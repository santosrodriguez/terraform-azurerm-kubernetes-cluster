 

resource "azurerm_key_vault" "kv" {
  name                = local.kv_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Azure RBAC (data plane authorization)
  rbac_authorization_enabled = true

  soft_delete_retention_days    = 30
  purge_protection_enabled      = true
  public_network_access_enabled = false

  network_acls {
    bypass         = "None"
    default_action = "Deny"
  }
  lifecycle {
    ignore_changes = [ tags ]
  }


}

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-${azurerm_key_vault.kv.name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.keyvault_subnet.id


  private_service_connection {
    name                           = "psc-${azurerm_key_vault.kv.name}"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.keyvault_privatelink_zone.id]
  }
  lifecycle {
    ignore_changes = [ tags ]
  }
}
