param containerAppsEnvName string = 'ignite-albums-demo'
param location string = resourceGroup().location
param vnetName string = 'vnet-${containerAppsEnvName}'
param vnetPrefix string = '10.0.0.0/16'

// Define subnets for deployment to Virtual Network
var containerAppsSubnet = {
  name: 'ContainerAppsSubnet'
  properties: {
    addressPrefix: '10.0.0.0/23'
  }
}

var subnets = [
  containerAppsSubnet
]

// Azure Key Vault Params
@description('The name of the key vault to be created.')
param vaultName string = 'kv-${uniqueString(containerAppsEnvName)}'
param secretStoreName string = 'secretstore'

// Storage Account Params 
param storageAccountName string = 'storage${replace(containerAppsEnvName, '-', '')}'
param blobContainerName string = 'albums'

param managedIdentityName string = 'dapr-albums-mi'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

// Deploy an Azure Virtual Network 
module vnetModule 'modules/vnet.bicep' = {
  name: '${deployment().name}--vnet'
  params: {
    location: location
    vnetName: vnetName
    vnetPrefix: vnetPrefix
    subnets: subnets
  }
}

// Deploy Container Apps environment and supporting resources
module cappsEnvModule 'modules/containerapps-env.bicep' = {
  name: '${deployment().name}--cappsenv'
  params: {
    containerAppsEnvName: containerAppsEnvName
    location: location 
    envSubnet: '${vnetModule.outputs.vnetId}/subnets/${containerAppsSubnet.name}'
  }
  dependsOn:[
    vnetModule
  ]
}

// Deploy Azure Container Registry 
module azureContainerRegistryModule 'modules/azure-container-registry.bicep' = {
  name: '${deployment().name}--acr'
  params: {
    location : location
    containerRegistryName: 'acr${replace(containerAppsEnvName, '-', '')}'
    identityPrincipalId: managedIdentity.properties.principalId
} 
}

// Deploy Azure Key Vault 
module azureKeyVaultModule 'modules/azure-key-vault.bicep' = {
  name: '${deployment().name}--kv'
  params: {
    location : location
    managedIdentity: managedIdentity.properties.clientId
    vaultName: vaultName
} 
}

module daprSecretStore 'modules/dapr-secretstore.bicep' = {
  name: '${deployment().name}--dapr-secretstore'
  params: {
    containerAppsEnvName : containerAppsEnvName
    vaultName: vaultName
    identityClientId: managedIdentity.properties.clientId
    secretStoreName : secretStoreName
}
dependsOn:[
  cappsEnvModule
  azureKeyVaultModule
]
}

// Deploy Azure Storage and store keys in KV
module azureStorageModule 'modules/azure-storage.bicep' = {
  name: '${deployment().name}--azure-blob'
  params: {
    location : location
    storageAccountName: storageAccountName
    blobContainerName: blobContainerName
    vaultName: vaultName
} 
dependsOn:[
  azureKeyVaultModule
]
}

// Deploy Dapr component for Azure Storage 
module daprStateStoreBlob 'modules/dapr-statestore-blob.bicep' = {
  name: '${deployment().name}--dapr-statestore'
  params: {
    containerAppsEnvName : containerAppsEnvName
    storage_account_name: storageAccountName
    storage_container_name: blobContainerName
    secretStoreName: secretStoreName
}
dependsOn:[
  cappsEnvModule
  azureStorageModule
  daprSecretStore
]
}


