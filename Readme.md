# Azure Functions Stripe Web Hook Handler
Sample application showing how to create a web hook handler for Stripe events using Azure Functions and C#


## Prerequisites

* [.NET SDK v8.0+](https://get.dot.net/)
* [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
### Accounts
* [Azure Account](https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account)
* [Stripe Account](https://dashboard.stripe.com/register)


## Setup

1. Deploy the infrastucture using the [deploy](.deploy/deploy.sh) script

```shell
> source .deploy/deploy.sh
```

The script uses the `az` cli to create a deployment using the provided [bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview?tabs=bicep) files. The deployment inlcudes:
- An Azure Service Bus namespace
- An Azure Function App
- An Azure Storage account
- An Azure Key vault instance with stripe keys
- A managed Identity w/ Servce Bus and Key Vault role assignment