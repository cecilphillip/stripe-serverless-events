param serviceBusName string
param principalName string

@allowed([
  'Reader'
  'Sender'
  'Owner'
])
param role string

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: principalName
}

var readerRoleId = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0' // Azure Service Bus Data Receiver
var senderRoleId = '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39' // Azure Service Bus Data Sender
var ownerRoleId = '090c5cfd-751d-490a-894a-3ce6f1109419' // Azure Service Bus Data Owner

var roleId = role == 'Reader' ? readerRoleId : role == 'Sender' ? senderRoleId : ownerRoleId

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(servicebus.id, roleId, msi.id)
  //scope: servicebus
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalId: msi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
