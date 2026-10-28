locals {
  name_suffix = "${var.app_name}-${var.location}-${var.environment}"

 
  aks_name = "aks-${local.name_suffix}-${random_string.suffix.result}"
  managed_id_name = "id-aks-${local.name_suffix}-${random_string.suffix.result}"

  agw_name = "agic-aks-${local.name_suffix}-${random_string.suffix.result}"
  pip_name   = "pip-${local.name_suffix}-${random_string.suffix.result}"
 
  waf_firewall_policy_name = "waf-${local.name_suffix}-${random_string.suffix.result}"

  kv_name = "kv${var.app_name}${var.location}${var.environment}"


}

resource "random_string" "suffix" {
  length = 4
  upper = false
  lower = false
  special = false
  numeric = true
}

