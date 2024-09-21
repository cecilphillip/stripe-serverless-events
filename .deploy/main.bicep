targetScope = 'subscription'

param resourceGroupName string = 'AzStripeEvents'
param rgLocation string = 'eastus2'
param queueName string = 'checkout.completed'
param managedIdentityName string = 'azStripeEventsIdentity'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: rgLocation
}

module managedIdentity 'userAssignedIdentities.bicep' = {
  name: 'managedIdentity'
  scope: rg
  params: {
    managedIdentityName: managedIdentityName
    location: rgLocation
  }
}

module servicebusMod 'servicebus.bicep' = {
  name: 'servicebusMod'
  scope: rg
  params: {
    location: rgLocation
    serviceBusQueueName: queueName
    serviceBusNamespaceName: rg.name
  }
}

module functionAppMod 'functionapp.bicep' = {
  name: 'functionApp'
  scope: rg
  params: {
    storageAccountName: '${toLower(resourceGroupName)}storage'
    serviceBusWorkerRuleName: servicebusMod.outputs.workerGlobalRuleName
    serviceBusNamespaceName: rg.name
    managedIdentityName: managedIdentity.outputs.identityName
  }
}

module managedIdentityRoleAssignment 'service-bus-role-assignment.bicep' = {
  name: 'managedIdentityRoleAssignment'
  scope: rg
  params: {
    serviceBusName: rg.name
    principalName: managedIdentity.outputs.identityName
    role: 'Owner'
  }
}
