resource "azurerm_public_ip" "appgw_pip" {
  name                = local.pip_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  lifecycle {
    ignore_changes = [ tags ]
  }

}
resource "azurerm_web_application_firewall_policy" "appgw" {
  name                = local.waf_firewall_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled = true
    mode    = "Detection"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
  lifecycle {
    ignore_changes = [ tags ]
  }
}


resource "azurerm_application_gateway" "appgw" {
  name                = local.agw_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  zones               = var.zones


  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }
  firewall_policy_id = azurerm_web_application_firewall_policy.appgw.id

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = data.azurerm_subnet.agic_subnet.id
  }

  frontend_ip_configuration {
    name                          = "private-ip"
    subnet_id                     = data.azurerm_subnet.agic_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.agic_frontend_private_ip
  }

  frontend_ip_configuration {
    name                 = "public-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  # Minimal skeleton; AGIC will manage most configuration.
  frontend_port {
    name = "http"
    port = 80
  }

  backend_address_pool {
    name = "default-backend"
  }

  backend_http_settings {
    name                  = "http-settings"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "private-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default-rule"
    priority                   = 10
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "default-backend"
    backend_http_settings_name = "http-settings"
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      probe,
      redirect_configuration,
      ssl_certificate,
      url_path_map,
      frontend_port,
      tags,
    ]
  }
}



##############################
## AGIC DIAGNOSTIC SETTINGS ##
##############################

resource "azurerm_monitor_diagnostic_setting" "agic" {
  name                       = "diagnostics-agic-${local.name_suffix}-01"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log-sharedsvcseastus.id
  enabled_metric {
    category = "AllMetrics"
    
  }
  enabled_log {
    category_group = "allLogs"
  }
}
