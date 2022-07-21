output "k8s_vnet_id" {
  value = azurerm_virtual_network.k8s.id
}

output "k8s_vnet_name" {
  value = azurerm_virtual_network.k8s.name
}