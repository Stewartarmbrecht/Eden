function Install-EdenServiceTools {
    [CmdletBinding()]
    param(  
    )
    
    try {
        $edenEnvConfig = Get-EdenEnvConfig
    
        $loggingPrefix = "$($edenEnvConfig.SolutionName) $($edenEnvConfig.ServiceName) Publish"

        Write-EdenBuildInfo "Installing the service tools." $loggingPrefix

        Invoke-EdenCommand "Install-ServiceTools" $edenEnvConfig $loggingPrefix
        
        Write-EdenBuildInfo "Finished installing the service tools." $loggingPrefix
    }
    catch {
        Write-EdenBuildError "Error installing the service tools. Message: '$($_.Exception.Message)'" $loggingPrefix
    }    
}
New-Alias `
    -Name e-eit `
    -Value Install-EdenServiceTools
