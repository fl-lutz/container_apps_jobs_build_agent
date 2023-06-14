param location string = resourceGroup().location
param lawName string

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
}
