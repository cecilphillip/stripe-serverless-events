param managedIdentityName string

var rgName = resourceGroup().name

resource sercretsVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${toLower(rgName)}-${skip(uniqueString(rgName), 10)}-vault'
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

@description('Built-in Key Vault Administrator role')
resource keyVaultAdministratorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
}

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sercretsVault.id, msi.id, keyVaultAdministratorRoleDefinition.id)
  //scope: sercretsVault
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyVaultAdministratorRoleDefinition.id
    principalId: msi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

var stripeSecrets = [
  'stripe-secret-key'
  'stripe-webhook-secret'
]

resource secrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [
  for secret in stripeSecrets: {
    name: toLower(secret)
    parent: sercretsVault
    properties: {
      value: 'FILL ME IN'
      contentType: 'text/plain'
      attributes: {
        enabled: true
      }
    }
  }
]

output vaultUri string = sercretsVault.properties.vaultUri
output vaultName string = sercretsVault.name
