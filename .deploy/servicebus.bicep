@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the assigned managed identity')
param managedIdentityName string

@description('Name of the Queue')
param serviceBusQueueName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource serviceBusCheckoutQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: serviceBusQueueName
  parent: serviceBusNamespace
  properties: {
    requiresDuplicateDetection: false
    deadLetteringOnMessageExpiration: false
    requiresSession: false
    maxDeliveryCount: 10
  }
}

resource serviceBusGlobalRules 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' = {
  name: 'GlobalWorkerRules'
  parent: serviceBusNamespace
  properties: {
    rights:['Listen', 'Send']
  }
}

resource serviceBusQueueRules 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-10-01-preview' = {
  name: 'FunctionWorkerRules'
  parent: serviceBusCheckoutQueue
  properties: {
    rights:['Listen', 'Send']
  }
}

module managedIdentityRoleAssignment 'service-bus-role-assignment.bicep' = {
  name: 'managedIdentityRoleAssignment'
  scope: resourceGroup()
  params: {
    serviceBusName: serviceBusNamespaceName
    principalName: managedIdentityName
    role: 'Owner'
  }
}


output workerGlobalRuleName string = serviceBusGlobalRules.name
output workerQueueRuleName string = serviceBusQueueRules.name
