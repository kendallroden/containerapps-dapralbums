param containerAppsEnvName string 
param envSubnet string 
param location string 
param logAnalyticsWorkspaceName string = 'log-${containerAppsEnvName}'
param appInsightsName string = 'appinsights-${containerAppsEnvName}'

// Log analytics and App Insights for visibility 
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId:logAnalyticsWorkspace.id
  }
}

// Container Apps environment 
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: containerAppsEnvName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    daprAIInstrumentationKey:appInsights.properties.InstrumentationKey
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: envSubnet
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }

}
