param location string = resourceGroup().location 
param containerAppsEnvName string 

// App specific params 
param apiImage string
param viewerImage string
param localRedis string = 'dapr-albums-test-redis'
param localRedisPort int = 6379

// Object ID for using Managed Identity to pull ACR images 
param acrIdentityResourceID string 
param acrRegistryServer string 

module albumViewerCapp 'modules/container-app.bicep' = {
  name: '${deployment().name}--album-viewer'
  dependsOn: [
    albumServiceCapp
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: 'album-viewer'
    containerImage: viewerImage
    targetPort: 3000
    transport: 'http'
    daprEnabled: true
    useIdentity: true
    acrRegistryServer: acrRegistryServer
  }
}

module albumServiceCapp 'modules/container-app.bicep' = {
  name: '${deployment().name}--album-api'
  dependsOn: [
    redisTestCapp
  ]
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: 'album-api'
    containerImage: apiImage
    targetPort: 8080
    transport: 'http'
    daprEnabled: true
    useIdentity: true
    acrIdentity: acrIdentityResourceID
    acrRegistryServer: acrRegistryServer
  }
}

module redisTestCapp 'modules/container-app.bicep' = {
  name: '${deployment().name}--local-redis'
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    appName: localRedis
    containerImage: 'docker.io/redis:7.0'
    targetPort: localRedisPort
    transport: 'tcp'
    useIdentity: false
    acrIdentity: acrIdentityResourceID
    acrRegistryServer: acrRegistryServer
  }
}

module daprStateStore 'modules/dapr-statestore-redis.bicep' = {
  name: '${deployment().name}--dapr-statestore'
  dependsOn:[
    redisTestCapp
  ]
  params: {
    containerAppsEnvName : containerAppsEnvName
    redisAppName: localRedis
    redisPort: localRedisPort
}
}
