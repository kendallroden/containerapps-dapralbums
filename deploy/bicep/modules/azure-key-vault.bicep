param location string
param tenantId string = subscription().tenantId
param vaultName string 
param managedIdentity string

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: vaultName
  location: location
  properties: {
    tenantId:  tenantId
    accessPolicies: [
      {
        objectId: managedIdentity
        tenantId: tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    sku: {
      name: 'premium'
      family: 'A'
    }
  }
}
