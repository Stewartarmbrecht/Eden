param(  
    [String] $shortCommand,
    [String] $command,
    [Alias("v")]
    [string] $verbosity,
    [String] $deploymentParameters,
    [string] $userName,
    [string] $password,
    [string] $tenantId,
    [string] $uniqueDeveloperId,
    [string] $systemName,
    [string] $region,
    [string] $solutionName,
    [string] $microserviceName,
    [int] $apiPort,
    [int] $workerPort
)

$currentDirectory = Get-Location

Set-Location "$PSScriptRoot"

$shortCommand = $shortCommand.ToLower()
$command = $command.ToLower()

$config = $shortCommand -eq "configure" -or $shortCommand -eq "config" -or $command -eq "configure" -or $command -eq "config"
$setup =  $shortCommand -eq "setup" -or     $shortCommand -eq "setup"  -or $command -eq "setup"     -or $command -eq "setup"

if (!$config -and !$setup) {

    $build =          $command -like "*build*" -or                $shortCommand -like "*b*"
    $continuoustest = $command -like "*test-continuous*" -or      $shortCommand -like "*tc*"
    $test = (         $command -like "*test*" -or                 $shortCommand -like "*t*") -and !$continuoustest
    $run =            $command -like "*run*" -or                  $shortCommand -like "*r*"
    $continuouse2e =  $command -like "*e2e-continuous*" -or       $shortCommand -like "*ec*"
    $e2e = (          $command -like "*e2e*" -or                  $shortCommand -like "*e*") -and !$continuouse2e
    $package =        $command -like "*package*" -or              $shortCommand -like "*k*"
    $deployAll =      $command -like "*deploy-all*" -or           $shortCommand -like "*dl*"
    $deployInfra =    $command -like "*deploy-infrastructure" -or $shortCommand -like "*di*"
    $deployApps =     $command -like "*deploy-apps*" -or          $shortCommand -like "*da*"
    $deploySubs =     $command -like "*deploy-subscriptions*" -or $shortCommand -like "*ds*"
    $pipeline =       $command -like "*pipeline*" -or             $shortCommand -like "*p*"
    
    if($continuoustest -and 
        ( $run -or $continuouse2e -or $e2e -or $package -or $deployAll -or $deployInfra -or $deployApps -or $deploySubs -or $pipeline)
    ) {
       Write-Error "You can not run continuous testing and any downstream commands." 
       exit
    }
    
    if($run -and 
        ( $continuouse2e -or $e2e -or $package -or $deployAll -or $deployInfra -or $deployApps -or $deploySubs -or $pipeline)
    ) {
       Write-Error "You can not issue the run command and any downstream commands." 
       exit
    }
    
    if($continuouse2e -and 
        ( $package -or $deployAll -or $deployInfra -or $deployApps -or $deploySubs -or $pipeline)
    ) {
       Write-Error "You can not issue the e2e continuous command and any downstream commands." 
       exit
    }
    
}

if ($config) {
    Set-Location "$PSScriptRoot"
    ./configure-env.ps1 `
        -systemName $systemName `
        -region $region `
        -solutionName $solutionName `
        -microserviceName $microserviceName `
        -apiPort $apiPort `
        -workerPort $workerPort `
        -deploymentParameters $deploymentParameters `
        -userName $userName `
        -password $password  `
        -tenantId $tenantId `
        -uniqueDeveloperId $uniqueDeveloperId
    Set-Location $currentDirectory
    exit
}

if ($setup) {
    Set-Location "$PSScriptRoot"
    ./setup.ps1
    Set-Location $currentDirectory
    exit
}

if ($pipeline) {
    Set-Location "$PSScriptRoot"
    ./pipeline.ps1 -v $verbosity
    Set-Location $currentDirectory
    exit
}

if ($build) {
    Set-Location "$PSScriptRoot"
    ./build.ps1 -v $verbosity
    Set-Location $currentDirectory
}

if ($test) {
    Set-Location "$PSScriptRoot"
    ./test-unit.ps1 -v $verbosity
    Set-Location $currentDirectory
}

if ($continuoustest) {
    Set-Location "$PSScriptRoot"
    ./test-unit.ps1 -v $verbosity -c $TRUE
}

if ($run) {
    Set-Location "$PSScriptRoot"
    ./run.ps1 -v $verbosity
}

if ($e2e) {
    Set-Location "$PSScriptRoot"
    ./run.ps1 -t $TRUE -v $verbosity
    Set-Location $currentDirectory
}

if ($continuouse2e) {
    Set-Location "$PSScriptRoot"
    ./run.ps1 -t $TRUE -c $TRUE -v $verbosity
}

if ($package) {
    Set-Location "$PSScriptRoot"
    ./package.ps1 -v $verbosity
    Set-Location $currentDirectory
}

if ($deployInfra -or $deployAll) {
    Set-Location "$PSScriptRoot"
    ./deploy-infrastructure.ps1 -v $verbosity
    Set-Location $currentDirectory
}

if ($deployApps -or $deployAll) {
    Set-Location "$PSScriptRoot"
    ./deploy-apps.ps1 -v $verbosity
    Set-Location $currentDirectory
}

if ($deploySubs -or $deployAll) {
    Set-Location "$PSScriptRoot"
    ./deploy-subscriptions.ps1 -v $verbosity
    Set-Location $currentDirectory
}

Set-Location $currentDirectory