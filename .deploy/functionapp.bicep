param storageAccountName string
param serviceBusWorkerRuleName string
param serviceBusNamespaceName string
param managedIdentityName string
param keyVaultName string

var location = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

var hostingPlanName = '${resourceGroup().name}-hplan'

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
}

var siteName = 'funcApp-${uniqueString(resourceGroup().id)}'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: siteName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: serviceBusNamespaceName
}

resource serviceBusQueueRules 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' existing = {
  name: serviceBusWorkerRuleName
  parent: serviceBusNamespace
}

var sbqnr = serviceBusQueueRules.listKeys().primaryConnectionString

var stripeSecrets = [
  'stripe-secret-key'
  'stripe-webhook-secret'
]

resource sercretsVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
resource stripeSecretKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = {
  name: stripeSecrets[0]
  parent: sercretsVault
}

resource stripeWebHookSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = {
  name: stripeSecrets[1]
  parent: sercretsVault
}

resource site 'Microsoft.Web/sites@2022-03-01' = {
  name: siteName
  kind: 'functionapp,linux'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${msi.id}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: false
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'ServiceBusConnection'
          value: sbqnr
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'STRIPE_WEBHOOK_SECRET'
          value: '@Microsoft.KeyVault(SecretUri=${stripeWebHookSecret.properties.secretUri})'
        }
        {
          name: 'STRIPE_SECRET_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${stripeSecretKey.properties.secretUri})'
        }
      ]
      keyVaultReferenceIdentity: msi.id
    }
    keyVaultReferenceIdentity: msi.id
  }
}
