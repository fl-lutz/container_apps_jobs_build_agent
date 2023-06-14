Param(
    [String]
    $subscription,
    [String]
    $resourceGroupName,
    [String]
    $location = "westeurope",
    [String]
    $locationShort = "weu",
    [String]
    $agentName = "ca-buildagent",
    [String]
    $poolId,
    [String]
    $poolName,
    [String]
    $azpUrl,
    [String]
    $azpToken,
    [Switch]
    $buildDockerImage = $False,
    [Switch]
    $vnetIntegration = $False
)

Set-AzContext -Subscription $subscription

Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent)
{
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}
#Log Analytics Workspace
$lawName = $agentName + "-law-" + $locationShort

$lawParameters = @{ }
$lawParameters['lawName'] = $lawName

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "./law.bicep" -TemplateParameterObject $lawParameters

#Azure Container Registry
$acrName = ($agentName + "acr" + $locationShort).replace('-', '').ToLower()

$acrParameters = @{ }
$acrParameters['acrName'] = $acrName

$acrLoginServer = (New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "./acr.bicep" `
    -TemplateParameterObject $acrParameters).Outputs.acrLoginServer.value 

#Build Docker Image and Upload to ACR
$imageName = ($agentName + "image:latest").replace('-', '').ToLower()
$acrImagePath = $acrLoginServer + "/" + $imageName

if ($buildDockerImage)
{
    az account set --subscription $subscription
    az acr login --name $acrName
    cd ./image
    docker build -t $imageName .
    docker tag $imageName $acrImagePath
    docker push $acrImagePath
    cd ..
}


# Vnet
$vnetName = $agentName + "-vnet-" + $locationShort
$subnetName = "default"
if ($vnetIntegration){
    $vnetParameters = @{ }
    $vnetParameters['vnetName'] = $vnetName
    $vnetParameters['nsgName'] = $agentName + "-nsg-" + $locationShort
    $vnetParameters['subnetName'] = $subnetName
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "./vnet.bicep" -TemplateParameterObject $vnetParameters
}

#CA Environment
$envName = $agentName + "-cae-" + $locationShort
$envParameters = @{ }
$envParameters['envName'] = $envName
$envParameters['lawName'] = $lawName
$envParameters['vnetIntegration'] = [bool]$vnetIntegration
$envParameters['vnetName'] = $vnetName
$envParameters['subnetName'] = $subnetName

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "./ca_environment.bicep" -TemplateParameterObject $envParameters


#Container App Jobs
$jobParameters = @{ }
$jobParameters['jobName'] = $agentName + "-job-" + $locationShort
$jobParameters['envName'] = $envName
$jobParameters['acrName'] = $acrName
$jobParameters['imageName'] = $imageName
$jobParameters['poolId'] = $poolId
$jobParameters['poolName'] = $poolName
$jobParameters['azpToken'] = $azpToken
$jobParameters['azpUrl'] = $azpUrl


New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "./ca_job.bicep" -TemplateParameterObject $jobParameters