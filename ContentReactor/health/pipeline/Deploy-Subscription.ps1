[CmdletBinding()]
param()
$currentDirectory = Get-Location
Set-Location $PSScriptRoot

. ./Functions.ps1

./Configure-Environment.ps1

$instanceName = $Env:InstanceName
$region = $Env:Region

$loggingPrefix = "ContentReactor Audio Deploy Subscriptions $instanceName"

$eventsResourceGroupName = "$instanceName-events"
$eventsSubscriptionDeploymentFile = "./../infrastructure/subscriptions.json"

Write-BuildInfo "Deploying the microservice subscriptions." $loggingPrefix

Connect-AzureServicePrincipal $loggingPrefix

Write-BuildInfo "Deploying the event grid subscriptions for the functions app." $loggingPrefix
Write-BuildInfo "Deploying to '$eventsResourceGroupName' events resource group." $loggingPrefix
$result = New-AzResourceGroupDeployment -ResourceGroupName $eventsResourceGroupName -TemplateFile $eventsSubscriptionDeploymentFile -InstanceName $instanceName
if ($VerbosePreference -ne 'SilentlyContinue') { $result }

Write-BuildInfo "Deployed the microservice subscriptions." $loggingPrefix
Set-Location $currentDirectory