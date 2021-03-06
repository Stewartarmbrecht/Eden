function Initialize-EdenServiceEnvironment {
    [CmdletBinding()]
    param(  
    )
    
    try {
        $edenEnvConfig = Get-EdenEnvConfig -Check
    
        $loggingPrefix = "$($edenEnvConfig.SolutionName) $($edenEnvConfig.ServiceName) Initialize Environment"

        Write-EdenBuildInfo "Initializing the environment." $loggingPrefix

        Invoke-EdenCommand "Initialize-ServiceEnvironment" $edenEnvConfig $loggingPrefix
        
        Write-EdenBuildInfo "Finished initializing the environment." $loggingPrefix
    }
    catch {
        Write-EdenBuildError "Error initializing the environment. Message: '$($_.Exception.Message)'" $loggingPrefix
    }    
}
New-Alias `
    -Name e-ei `
    -Value Initialize-EdenServiceEnvironment
