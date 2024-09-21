param managedIdentityName string
param location string

// Managed Identity resources
resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

output identityName string = msi.name
