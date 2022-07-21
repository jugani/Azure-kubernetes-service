resource "azurerm_route_table" "k8s" {
  name                          = "k8s-networking-${var.name}-rt"
  location                      = var.azure_location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false

  # If a k8s service has no endpoints (even temporarily), traffic would be routed to
  # Azure firewall and denied, causing alerts, unless we have an explicit
  # rule to keep all k8s-internal traffic inside the VNet
  route {
    name           = "K8sInternalTraffic"
    address_prefix = var.k8s_cluster_private_ip_range
    next_hop_type  = "VnetLocal"
  }

  route {
    name                   = "DefaultGateway"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.egress_firewall_ip
  }

  #  The following rule is required because of:
  #  https://docs.microsoft.com/en-gb/azure/firewall/integrate-lb#asymmetric-routing
  route {
    name           = "FixLoadBalancerAsymmetricRule"
    address_prefix = "${var.azure_firewall_public_ip}/32"
    next_hop_type  = "Internet"
  }
}



resource "azurerm_subnet_route_table_association" "k8s_to_firewall" {
  route_table_id = azurerm_route_table.k8s.id
  subnet_id      = azurerm_subnet.k8s.id
}

# Using inline rules is against the best practice, but it's the only way we have to let
# Terraform detect and correct any manually added rule.
resource "azurerm_network_security_group" "k8s" {
  name                = "k8s-networking-${var.name}"
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  tags = {
    environment = var.name
  }
}

resource "azurerm_virtual_network_peering" "k8s_vnet_to_domain_services_vnet" {
  name                         = "${var.vnet_name}-to-${var.domain_services_vnet_name}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.vnet_name
  remote_virtual_network_id    = var.domain_services_vnet_id
  allow_virtual_network_access = true
}

module "domain_services_vnet_to_k8s_vnet_regional" {
  source                     = "../remote-peering/vnet-access"
  remote_vnet_name           = "${var.env_name}-k8s-vnet-${var.azure_location_id}-vnet"
  remote_vnet_id             = var.vnet_id
  peered_subscription_id     = var.general_subscription_id
  peered_resource_group_name = var.domain_services_resource_group_name
  peered_vnet_name           = var.domain_services_vnet_name
  name                       = "aad-domain-services"
}

resource "azurerm_virtual_network_peering" "management_vnet_to_k8s_vnet" {
  name                         = "${var.management_vnet_name}-to-${var.vnet_name}"
  resource_group_name          = var.management_resource_group_name
  virtual_network_name         = var.management_vnet_name
  remote_virtual_network_id    = var.vnet_id
  allow_virtual_network_access = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "k8s_vnet_to_management_vnet" {
  name                         = "${var.vnet_name}-to-${var.management_vnet_name}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.vnet_name
  remote_virtual_network_id    = var.management_vnet_id
  allow_virtual_network_access = true
}

output "k8s_subnet_id" {
  value = azurerm_subnet.k8s.id
}

output "k8s_network_security_group_id" {
  value = azurerm_network_security_group.k8s.id
}

# Create a Private DNS to VNET link
resource "azurerm_private_dns_zone_virtual_network_link" "privateendpoint-dns-zone-to-vnet-link" {
  count                   = var.enable_proxy_sql ? 1 : 0
  name                    = "private-endpoint-vnet-link"
  resource_group_name     = var.resource_group_name
  private_dns_zone_name   = azurerm_private_dns_zone.mysql-endpoint-dns-private-zone[count.index].name
  virtual_network_id      = var.vnet_id
}


