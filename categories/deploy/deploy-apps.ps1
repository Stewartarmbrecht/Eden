param([String]$namePrefix,[String]$region)
if (!$namePrefix) {
    $namePrefix = $Env:namePrefix
}
if (!$region) {
    $region = $Env:region
}
$loggingPrefix = "Categories Deployment ($namePrefix)"
$resourceGroupName = "$namePrefix-categories"
$apiName = "$namePrefix-categories-api"
$apiFilePath = "./ContentReactor.Categories.Api.zip"
$workerName = "$namePrefix-categories-worker"
$workerFilePath = "./ContentReactor.Categories.WorkerApi.zip"

Set-Location "$PSSCriptRoot"

. ./../../scripts/functions.ps1

if (!$namePrefix) {
    D "Either pass in the '-namePrefix' parameter when calling this script or 
    set and environment variable with the name: 'namePrefix'." $loggingPrefix
}
if (!$region) {
    D "Either pass in the '-region' parameter when calling this script or 
    set and environment variable with the name: 'region'." $loggingPrefix
}

$command = "az webapp deployment source config-zip --resource-group $resourceGroupName --name $apiName --src $apiFilePath"
$result = ExecuteCommand $command $loggingPrefix "Deploying the API application."

$command = "az webapp deployment source config-zip --resource-group $resourceGroupName --name $workerName --src $workerFilePath"
$result = ExecuteCommand $command $loggingPrefix "Deploying the worker application."