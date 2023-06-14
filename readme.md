## Intro
This Repository contains the Bicep adaption of my (blog post)[https://dev.to/florianlutz/use-container-app-jobs-for-scaling-devops-build-agents-7j6] about Container Apps Jobs Build Agents. Also the option of including the Build agents into a VNET is added.
## Prerequisites
- Connect-AzAcccount

if running Docker Build:
- run Docker Desktop
- az login

## Deploy the Resources:

./DeployCAJob.PS1 `
  -subscription <subscriptionId> `
  -resourceGroupName <resourceGroupName> `
  -location <loction> `
  -agentName <agentName> `
  -poolId <poolId> `
  -poolName <poolName> `
  -azpUrl <azpUrl> `
  -azpToken <azpToken> `
  -buildDockerImage `
  -vnetIntegration

  ### Build Docker Image
  can be skipped by leaving it out

  ### VnetIntegration
  leaving this will make the CA Environment & the Job Public