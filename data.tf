


data "azurerm_client_config" "current" {}


data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "aks_vnet" {
  name                = var.virtual_network_name
  resource_group_name = var.virtual_network_rg
}

data "azurerm_subnet" "aks_node_subnet" {
  name                 = var.node_subnet_name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
  resource_group_name  = data.azurerm_virtual_network.aks_vnet.resource_group_name
}

data "azurerm_subnet" "aks_pod_subnet" {
  name                 = var.pod_subnet_name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
  resource_group_name  = data.azurerm_virtual_network.aks_vnet.resource_group_name
}

data "azurerm_subnet" "agic_subnet" {
  name                 = var.agic_subnet_name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
  resource_group_name  = data.azurerm_virtual_network.aks_vnet.resource_group_name
}

data "azurerm_subnet" "keyvault_subnet" {
  name                 = var.keyvault_subnet_name
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
  resource_group_name  = data.azurerm_virtual_network.aks_vnet.resource_group_name
}

# AKS private dns zone
data "azurerm_resource_group" "rg-azuredns-prd-01" {
  name     = var.private_dns_zone_resource_group
  provider = azurerm.CS-PNP-CommonServicesInfra
}

data "azurerm_private_dns_zone" "aks_privatelink_zone" {
  name                = var.aks_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.rg-azuredns-prd-01.name
  provider            = azurerm.CS-PNP-CommonServicesInfra
}

data "azurerm_private_dns_zone" "keyvault_privatelink_zone" {
  name                = var.keyvault_private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.rg-azuredns-prd-01.name
  provider            = azurerm.CS-PNP-CommonServicesInfra
}

data "azurerm_log_analytics_workspace" "log-sharedsvcseastus" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_workspace_resource_group
  provider            = azurerm.CS-PNP-CommonServicesInfra
}
