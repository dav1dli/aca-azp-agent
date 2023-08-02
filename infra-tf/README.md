# Cloud infrastructure terraform stack

# Prerequisites
* access to Azure subscription with sufficient permissions
* terraform
* azure-cli
* operating user with permissions

# Getting Started
Due to security restrictions it is assumed that resource group is created in advance and imported into the state.
## Azure
Login to Azure:
```
az login
```
If needed select a subscription:
```
az account set --subscription XXXXX
```

## Terraform
Terraform stack is located in `tf` directory.

Initialize:
```
terraform init -var-file=env/poc/env.tfvars
terraform import azurerm_resource_group.rg \
  /subscriptions/XXXXXX/resourceGroups/RG-EUR-WW-POC
```
Plan:
```
terraform plan -var-file=env/poc/env.tfvars -out=test.tfplan
```
Apply:
```
terraform apply -input=false -auto-approve test.tfplan
```