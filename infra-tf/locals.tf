locals {
  resource_group               = "RG-${var.region}-${var.environment}-${var.project}"
  vnet_name                    = "VNET-${var.region}-${var.environment}-${var.project}"
  cap_subnet                   = "SBNT-CAP-${var.region}-${var.environment}-${var.project}"
  priv_endpt_subnet            = "SBNT-PEP-${var.region}-${var.environment}-${var.project}"
  acr_name                     = "ACR${var.environment}${var.project}"
  acr_pep_name                 = "PEP-ACR-${var.region}-${var.environment}-${var.project}"
  kv_name                      = "KV-${var.region}-${var.environment}-${var.project}"
  kv_pep_name                  = "PEP-KV-${var.region}-${var.environment}-${var.project}"
  cap_name                     = "CAP-${var.region}-${var.environment}-${var.project}"
  cap_user_identity            = "CAP-IDN-${var.region}-${var.environment}-${var.project}"
  log_analytics_workspace_name = "OMS-${var.region}-${var.environment}-${var.project}"
  ad_app                       = "AZU-${var.region}-${var.environment}-${var.project}"
}