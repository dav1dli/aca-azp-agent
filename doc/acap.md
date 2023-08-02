# Azure Pipelines Agent on Azure Container Apps
## Overview
See [Deploy self-hosted CI/CD runners and agents with Azure Container Apps jobs](https://learn.microsoft.com/en-us/azure/container-apps/tutorial-ci-cd-runners-jobs?tabs=bash&pivots=container-apps-jobs-self-hosted-ci-cd-azure-pipelines) for more details.
## Configuration Parameters
* AZP_POOLID - ID of the agents pool to which the agent is to be attached
* AZP_URL - AZDO Organization URL
* AZP_TOKEN

## Pre-requisites
* Azure CLI `az` + `containerapp` extension
* Azure DevOps organization
* Azure resources: resource group, Container Apps environment, ACR, Key Vault

## Deployment
*Note:* Commands are listed with variables how they are available in AZP.
It is required to have a template agent in the pool:
```
az containerapp job create -n "$(imgname)-template"  \
    -g $(RESOURCE_GROUP) \
    --environment $(CAP_ENV) \
    --trigger-type Manual \
    --replica-timeout 300 \
    --replica-retry-limit 1 \
    --replica-completion-count 1 \
    --parallelism 1 \
    --image $(ACR_NAME)/$(imgname):latest \
    --cpu "2.0" \
    --memory "4Gi" \
    --secrets "azp-token=$(AZDO-PAT)" \
    --env-vars "AZP_TOKEN=secretref:azp-token" AZP_URL=$(AZP_URL) \
    AZP_POOLID=$(CAP_POOLID) AZP_POOL=$(CAP_POOL) "AZP_AGENT_NAME=$(imgname)-template" \
    --registry-server $(ACR_NAME) --registry-username $(ACRUSER) --registry-password $(ACRPASS)
```
this agent never runs but serves as a placeholder in the agent pool. See `start-job.sh` and how it exits if there is `template` in the agent name.

Run the job to create the template agent:
```
az containerapp job start -n "$(imgname)-template" -g $(RESOURCE_GROUP)
```
The agent should appear in Azure DevOps -> Project settings -> Agent pools -> selected pool -> Agents with offline status.

Delete the job:
```
az containerapp job delete -n "$(imgname)-template" -g $(RESOURCE_GROUP)
```

Deploy the agent with user-assigned identity:
```
az containerapp job create -n $(imgname) \
    -g $(RESOURCE_GROUP) \
    --environment $(CAP_ENV) \
    --trigger-type Event \
    --replica-timeout 1800 --replica-retry-limit 1 \
    --replica-completion-count 1 --parallelism 1 \
    --image $(ACR_NAME)/$(imgname):latest \
    --cpu "0.25" --memory "0.5Gi" \
    --min-executions 0 --max-executions 10 --polling-interval 30 \
    --scale-rule-name "azure-pipelines" --scale-rule-type "azure-pipelines" \
    --scale-rule-metadata "poolID=$(CAP_POOLID)" "targetPipelinesQueueLength=1" \
    --scale-rule-auth "personalAccessToken=azp-token" "organizationURL=organization-url" \
    --secrets "azp-token=$(AZDO-PAT)" "organization-url=$(AZP_URL)" \
    --env-vars AZP_URL=$(AZP_URL) AZP_POOL=$(CAP_POOL) "AZP_TOKEN=secretref:azp-token" \
    --registry-server $(ACR_NAME)  --registry-username $(ACRUSER) --registry-password $(ACRPASS)
```

It is expected:
* a job in the Azure Container Apps Environment with a name ending with "template" to appear.
* Azure DevOps pipelines configured to use the agent pool with ACA Jobs as agents will wait until the scaler will create an ACA job, run it and finish.
* Agent jobs will register as agents in Azure DevOps and unregister when finished (not neccesseraly immediately).
## Automation
Pipeline `devops/pipelines/cap-deploy.yaml` provides an automation of the agent deployment. The agent is provisioned with secret parameters taken from the environment context, such as a key vault.

Provided example pipeline `devops/pipelines/cap-agent-test.yaml` tests the setup.

## Helpful commands

*Note:* normally those actions are performed by infrastructure creating pipelines.

Environment:
```
RESOURCE_GROUP="RG-WW-EUR-POC"
LOCATION="westeurope"
ENVIRONMENT="ACAENV-WW-EUR-POC"
CONTAINER_REGISTRY_NAME="ACR-WW-EUR-POC"
```

Create a resource group:
```
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION"```
```

Create a Container Apps Environment:
```
az containerapp env create \
    --name "$ENVIRONMENT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"
```

Create Azure Container Registry:
```
az acr create \
    --name "$CONTAINER_REGISTRY_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Basic \
    --admin-enabled true
```

Check job execution:
```
az containerapp job execution list \
    --name "$JOB_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --output table \
    --query '[].{Status: properties.status, Name: name, StartTime: properties.startTime}'
```