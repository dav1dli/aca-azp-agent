location="westeurope"
project="DL"
environment="POC"
region="EUR-WW"

agent_config = {
  name             = "azp-agent"
  image            = "acrXXXX.azurecr.io/azdo-agent"
  version          = "latest"
  azp_url          = "https://dev.azure.com/ORGANISATION"
  agent_pool       = "cap-pool"
  agent_pool_id    = "23"
  cpu              = 2
  memory           = "4Gi"
  max_replicas     = 5
  polling_interval = 30
  timeout          = 1800
  capabilities     = []
}

tags = {
  ApplicationName = "Terraform Delivery Agent Pool"
  Organization    = "Organisation"
  Environment     = "Test"
  ManagedBy       = "DevOps"
  Location        = "EU"
  createdWith     = "Terraform"
}