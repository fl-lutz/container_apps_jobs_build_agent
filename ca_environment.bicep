param location string = resourceGroup().location
param envName string
param lawName string
param vnetIntegration bool
param vnetName string
param subnetName string

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: lawName
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = if (vnetIntegration) {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = if (vnetIntegration) {
  name: subnetName
  parent: vnet
}

resource caEnv 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: vnetIntegration ? {
      infrastructureSubnetId: subnet.id
      internal: vnetIntegration
    } : {}
  }
}
