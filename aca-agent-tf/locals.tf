locals {
  resource_group               = "RG-${var.region}-${var.environment}-${var.project}"
  acr_name                     = "ACR${var.environment}${var.project}"
  kv_name                      = "KV-${var.region}-${var.environment}-${var.project}"
  aca_env_name                 = "CAP-${var.region}-${var.environment}-${var.project}"
  aca_name                     = "azp-agent-job"
  aca_user_identity            = "CAP-IDN-${var.region}-${var.environment}-${var.project}"
  ad_app_name                  = "AZU-${var.region}-${var.environment}-${var.project}"
}