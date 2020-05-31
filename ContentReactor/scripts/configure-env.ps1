param(
    [String] $systemName, 
    [String] $region, 
    [String] $deploymentParameters, 
    [String] $userName, 
    [String] $password, 
    [String] $tenantId, 
    [String] $uniqueDeveloperId, 
    [String] $solutionName,
    [String] $microserviceName,
    [Int] $apiPort,
    [Int] $workerPort
)

if ($systemName) {
    $Env:systemName = $systemName
}
if ($region) {
    $Env:region = $region
}
if ($deploymentParameters) {
    $Env:deploymentParameters = $deploymentParameters
}
if ($userName) {
    $Env:userName = $userName
}
if ($password) {
    $Env:password = $password
}
if ($tenantId) {
    $Env:tenantId = $tenantId
}
if ($uniqueDeveloperId) {
    $Env:uniqueDeveloperId = $uniqueDeveloperId
}
if ($solutionName) {
    $Env:solutionName = $solutionName
}
if ($microserviceName) {
    $Env:microserviceName = $microserviceName
}
if ($apiPort) {
    $Env:apiPort = $apiPort
}
if ($workerPort) {
    $Env:workerPort = $workerPort
}

if(!$Env:systemName) {
    $Env:systemName = Read-Host -Prompt 'Please provide a prefix to add to the beginning of every resource.  Some resources require globally unique names.  This prefix should guarantee that.'
}
if(!$Env:region) {
    $Env:region = Read-Host -Prompt 'Please provide a region to deploy to.  Hint: WestUS2'
}
if(!$Env:deploymentParameters) {
    $Env:deploymentParameters = Read-Host -Prompt 'Please provide the deployment parameters for your deployment template.'
}
if(!$Env:userName) {
    $Env:userName = Read-Host -Prompt 'Please provide the Application (client) ID for a service principle to use for the deployment.'
}
if(!$Env:password) {
    $Env:password = Read-Host -Prompt 'Please provide the service principal secret (password) to use for the deployment.'
}
if(!$Env:tenantId) {
    $Env:tenantId = Read-Host -Prompt 'Please provide the Directory (tenant) ID for the service principal.'
}
if(!$Env:uniqueDeveloperId) {
    $Env:uniqueDeveloperId = Read-Host -Prompt 'Please provide a unique id to identify subscriptions deployed to the cloud for the local developer.'
}
if(!$Env:solutionName) {
    $Env:solutionName = Read-Host -Prompt 'Please provide the solution name.'
}
if(!$Env:microserviceName) {
    $Env:microserviceName = Read-Host -Prompt 'Please provide the microservice name.'
}
if(!$Env:apiPort) {
    $Env:apiPort = Read-Host -Prompt 'Please provide the port number for the api.'
}
if(!$Env:workerPort) {
    $Env:workerPort = Read-Host -Prompt 'Please provide the port number for the worker api.'
}