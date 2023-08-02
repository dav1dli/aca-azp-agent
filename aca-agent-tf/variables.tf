variable "location" {
  type = string
  description = "Azure Region where resources will be provisioned"
  default = "westeurope"
}
variable "environment" {
  type = string
  description = "Environment"
  default = ""
}

variable "project" {
  type = string
  description = "Application project"
  default = ""
}

variable "region" {
  type = string
  description = "Environment region"
  default = "EUR-WW"
}
variable "tags" {
  description = "Specifies tags for all the resources"
  default     = {
    createdWith = "Terraform"
  }
}

variable "agent_config" {
  type = object({
    name             = string # name of the agent/job
    image            = string # path to the acr repository
    version          = string # version of the agent image
    azp_url          = string # url of the target Azure Devops Org.
    agent_pool       = string # name of the target Agent Pool in Azure DevOps.
    agent_pool_id    = string # id of the agent pool. Found in organisation settings in Ado.
    cpu              = number # hardware setings
    memory           = string # hardware settings.
    max_replicas     = number # maximum number of concurenlty spinned agent jobs.
    polling_interval = number # how often will the scaler check the queue (in seconds).
    timeout          = number # timeout when the agent container job will be terminaed (in seconds).
    capabilities = set(string) # currenlty not used! Values that indicated what workloads the agent can support.
  })
}