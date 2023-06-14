param location string = resourceGroup().location
param jobName string
param acrName string
param envName string
param imageName string
param poolId string
param poolName string
@secure()
param azpToken string
@secure()
param azpUrl string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource caEnv 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: envName
}

resource symbolicname 'Microsoft.App/jobs@2023-04-01-preview' = {
  name: 'ca-buildagent'
  location: location
  properties: {
    configuration: {
      registries: [
        {
          passwordSecretRef: 'acr-password'
          server: acr.properties.loginServer
          username: acr.listCredentials().username
        }
      ]
      replicaRetryLimit: 0
      replicaTimeout: 7200
      eventTriggerConfig: {
        replicaCompletionCount: 1
        parallelism: 1
        scale: {
          minExecutions: 0
          maxExecutions: 1
          pollingInterval: 1
          rules: [
            {
              name: 'azure-pipelines'
              type: 'azure-pipelines'
              metadata: {
                organizationURLFromEnv: 'AZP_URL'
                personalAccessTokenfromEnv: 'AZP_TOKEN'
                poolID: poolId
                poolName: poolName
              }
            }
          ]
        }
      }
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
        {
          name: 'azp-pool'
          value: poolName
        }
        {
          name: 'azp-token'
          value: azpToken
        }
        {
          name: 'azp-url'
          value: azpUrl
        }
      ]
      triggerType: 'Event'
    }
    environmentId: caEnv.id
    template: {
      containers: [
        {
          env: [
            {
              name: 'AZP_POOL'
              secretRef: 'azp-pool'
            }
            {
              name: 'AZP_TOKEN'
              secretRef: 'azp-token'
            }
            {
              name: 'AZP_URL'
              secretRef: 'azp-url'
            }
          ]
          image: '${acr.properties.loginServer}/${imageName}'
          name: jobName
          resources: {
            cpu: json('1')
            memory: '2Gi'
          }
        }
      ]
    }
  }
}
