param containerRegistryName string 
param location string
param identityPrincipalId string 

resource azureContainerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
  }
}

resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: azureContainerRegistry
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: azureContainerRegistry
  name: guid(azureContainerRegistry.id, identityPrincipalId, acrPullRoleDefinition.id)
  properties: {
    roleDefinitionId: acrPullRoleDefinition.id
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
