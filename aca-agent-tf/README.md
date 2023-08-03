# Azure Pipeline agent terraform stack
This terraform stack is an alternative to the pipeline deployment method used in `devops/pipelines/cap-deploy.yaml`.

# Prerequisites
* access to Azure subscription with sufficient permissions
* operating user with permissions

# Getting Started
It is assumed that cloud infrastructure was created using the terraform stack in `../infra-tf`.

The agent container is built with `devops/pipelines/img-build.yaml` and published to ACR created by infrastructure terraform stack.

Azure Pipelines agent is configured with following parameters:
* AZP_URL - AZDO organization URL https://dev.azure.com/{your-organization} (for example, https://dev.azure.com/Organization)
* AZP_TOKEN - [PAT token](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/linux-agent?view=azure-devops#authenticate-with-a-personal-access-token-pat)
* AZP_POOL - [AZDO agent pool](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=yaml%2Cbrowser)

`AZP_URL` and `AZP_POOL` are configured per environment.

`AZP_TOKEN` is generated out of scope of this stack and provided as a key vault secret.

## Azure
Login to Azure:
```
az login
```
If needed select a subscription:
```
az account set --subscription <SUBSCRIPTION>
```

## Terraform
Terraform stack is located in `tf` directory.

Initialize:
```
terraform init -var-file=env/poc/env.tfvars
```
Plan:
```
terraform plan -var-file=env/poc/env.tfvars -out=agent.tfplan
```
Apply:
```
terraform apply -input=false -auto-approve agent.tfplan
```

## Agent container
Agent Dockerfile is provided. It is triggered by Azure Pipeline job queue event, starts, connects to Azure DevOps, pics a job from a queue, runs it and ends. The container is not supposed to run continuously.

# Additional secrets
`az keyvault secret set --name AZDO-PAT --vault-name KV-EUR-WW-POC-DL --value <PAT-TOKEN>`

`az keyvault secret set --name AZU-EUR-WW-POC-DL --vault-name KV-EUR-WW-POC-DL --value <Registered App secret>`