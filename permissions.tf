##############################################
# Key Vault Azure RBAC (no access policies)
##############################################

resource "azurerm_role_assignment" "kv_admins" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.keyvault_admin_group_object_id
}

##############################################
# Post-create permissions for addon identities
##############################################

# AGIC addon identity RBAC (identity is created by AKS when AGIC addon is enabled)
resource "azurerm_role_assignment" "agic_appgw_contrib" {
  count                = var.enable_agic_addon ? 1 : 0
  scope                = azurerm_application_gateway.appgw.id
  role_definition_name = "Contributor"

  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

  depends_on = [time_sleep.post_aks_wait]
}

resource "azurerm_role_assignment" "agic_subnet_netcontrib" {
  count                = var.enable_agic_addon ? 1 : 0
  scope                = data.azurerm_subnet.agic_subnet.id
  role_definition_name = "Network Contributor"

  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

  depends_on = [time_sleep.post_aks_wait]
}

# Optional; keep only if you see AGIC needing RG read access in logs.
resource "azurerm_role_assignment" "agic_rg_reader" {
  count                = var.enable_agic_addon ? 1 : 0
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Reader"

  principal_id = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

  depends_on = [time_sleep.post_aks_wait]
}

# Key Vault Secrets Provider identity RBAC on the vault (identity is created by AKS)
resource "azurerm_role_assignment" "kv_secrets_provider_user" {
  count                = var.enable_key_vault_secrets_provider ? 1 : 0
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"

  principal_id = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  depends_on = [time_sleep.post_aks_wait]
}

# Key Vault Secrets Provider identity RBAC on the vault (identity is created by AKS)
resource "azurerm_role_assignment" "kv_certificates_officer" {
  count                = var.enable_key_vault_secrets_provider ? 1 : 0
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Certificates Officer"

  principal_id = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  depends_on = [time_sleep.post_aks_wait]
}

# Key Vault Secrets Provider identity RBAC on the vault (identity is created by AKS)
resource "azurerm_role_assignment" "kv_crypto_officer" {
  count                = var.enable_key_vault_secrets_provider ? 1 : 0
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Officer"

  principal_id = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  depends_on = [time_sleep.post_aks_wait]
}

# Key Vault Secrets Provider identity RBAC on the vault (identity is created by AKS)
resource "azurerm_role_assignment" "kv_secrets_officer" {
  count                = var.enable_key_vault_secrets_provider ? 1 : 0
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"

  principal_id = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  depends_on = [time_sleep.post_aks_wait]
}

resource "azurerm_role_assignment" "aks_dns_role_assignment" {
  scope                = data.azurerm_private_dns_zone.aks_privatelink_zone.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_uai.principal_id
}
resource "azurerm_role_assignment" "keyvault_dns_role_assignment" {
  scope                = data.azurerm_private_dns_zone.keyvault_privatelink_zone.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_uai.principal_id
}


resource "azurerm_role_assignment" "log-sharedsvcseastus" {
  scope                = data.azurerm_log_analytics_workspace.log-sharedsvcseastus.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_uai.principal_id
}
