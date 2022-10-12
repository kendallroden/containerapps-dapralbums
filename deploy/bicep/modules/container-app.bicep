param containerAppsEnvName string 
param appName string 
param location string 
param targetPort int
param containerImage string 
param transport string 
param daprEnabled bool = false
param useIdentity bool = false
param useACR bool = true 
param acrIdentity string = ''
param acrRegistryServer string 

resource caEnvironment 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: containerAppsEnvName
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' ={
  name: appName
  location: location
  identity: useIdentity ? {
    type: 'UserAssigned'
    userAssignedIdentities: [
    ]
  }: null
  properties:{
    managedEnvironmentId: caEnvironment.id
    configuration: {
      ingress: {
        targetPort: targetPort
        external: true
        transport: transport
      }
      registries: useACR ? [
        {
          identity: acrIdentity
          server: acrRegistryServer
        }
      ]: null
      dapr: daprEnabled ? {
        enabled: true
        appId: appName
        appProtocol: 'http'
        appPort: targetPort
      }: null
    }
    template: {
      containers: [
        {
          image: containerImage
          name: appName
        }
      ]
    }
  }
}
