## Networking
data "terraform_remote_state" "global" {
  backend = "azurerm"

  config = {
    storage_account_name = "labtfstate${var.azure_location_id}"
    container_name       = "tfstate"
    key                  = "global.terraform.tfstate"
  }
}

data "azurerm_subscription" "current" {
}

module "networking" {
  source                                        = "../../../modules/clusternetworking-regional"
  name                                          = "${var.env_name}-${var.azure_location_id}"
  azure_location                                = var.azure_location
  azure_location_id                             = var.azure_location_id
  env_name                                      = var.env_name
  vnet_address_space                            = data.terraform_remote_state.global.outputs.k8s_regional_vnet_address_space
  vnet_name                                     = data.terraform_remote_state.global.outputs.k8s_regional_vnet_name
  vnet_id                                       = data.terraform_remote_state.global.outputs.k8s_regional_vnet_id
  resource_group_name                           = data.terraform_remote_state.global.outputs.k8s_regional_resource_group_name
  k8s_cluster_private_ip_range                  = var.k8s_cluster_private_ip_range
  subscription_id                               = data.azurerm_subscription.current.subscription_id
  subscription_name                             = var.env_name
  private_link_endpoint                         = lookup(var.private_link_endpoint[var.env_name], var.azure_location_id)
}
