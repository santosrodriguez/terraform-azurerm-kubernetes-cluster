output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "application_gateway_id" {
  value = azurerm_application_gateway.appgw.id
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "aks_id" {
  value = azurerm_kubernetes_cluster.aks.id
}
