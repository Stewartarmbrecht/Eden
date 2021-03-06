function Start-EdenServiceLocal
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias("c")]
        [Switch]$Continuous,
        [Parameter()]
        [switch]$RunFeatureTests,
        [Parameter()]
        [switch]$RunFeatureTestsContinuously
    )
    
    try {
    
        $edenEnvConfig = Get-EdenEnvConfig -Check
    
        $loggingPrefix = "$($edenEnvConfig.SolutionName) $($edenEnvConfig.ServiceName) Run $($edenEnvConfig.EnvironmentName)"

        Write-EdenBuildInfo "Starting the local service." $loggingPrefix

        if ($Continuous) {
            $startCommand = "Start-ServiceLocalContinuous"
        } else {
            $startCommand = "Start-ServiceLocal"
        }
        
        Write-EdenBuildInfo "Starting the local service job." $loggingPrefix
        $serviceJob = Start-EdenCommand `
            -EdenCommand $startCommand `
            -EdenEnvConfig $edenEnvConfig `
            -LoggingPrefix $loggingPrefix

        Write-EdenBuildInfo "Starting the public tunnel job." $loggingPrefix
        $tunnelJob = Start-EdenCommand `
            -EdenCommand "Start-ServiceLocalTunnel" `
            -EdenEnvConfig $edenEnvConfig `
            -LoggingPrefix $loggingPrefix

        $serviceReady = $false
        $subscriptionsDeployed = $false
        $publicUrl = $null

        # Write-Verbose "Before: Service Job: $($serviceJob.State)"
        # Write-Verbose "Before: Tunnel Job: $($tunnelJob.State)"
        # Write-Verbose "Before: Testing Job: $($testingJob.State)"

        While (!$serviceJob -or $serviceJob.State -eq "NotStarted" -or !$tunnelJob -or $tunnelJob.State -eq "NotStarted") {}

        While(`
            ($serviceJob.State -eq "Running" -or $serviceJob.State -eq "NotStarted") `
            -and ($tunnelJob.State -eq "Running" -or $tunnelJob.State -eq "NotStarted") `
            -and ($null -eq $testingJob -or $testingJob.State -eq "Running" -or $testingJob.State -eq "NotStarted"))
        {
            if (!$serviceReady) {
                Write-EdenBuildInfo "Checking whether the local service is ready." $loggingPrefix
                $serviceReady = Invoke-EdenCommand "Get-ServiceHealthLocal" $edenEnvConfig $loggingPrefix
                if ($serviceReady) {
                    Write-EdenBuildInfo "The local service passed the health check." $loggingPrefix    
                } else {
                    Write-EdenBuildError "The local service failed the health check." $loggingPrefix    
                }
            } 
            if ($serviceReady -and [string]::IsNullOrEmpty($publicUrl)) {
                Write-EdenBuildInfo "Getting the local service public url." $loggingPrefix
                $publicUrl = Invoke-EdenCommand "Get-ServiceUrlPublicLocal" $edenEnvConfig $loggingPrefix
                if ($publicUrl) {
                    $edenEnvConfig.PublicUrlToLocalWebServer = $publicUrl
                    Write-EdenBuildInfo "The local service has a public url: '$publicUrl'." $loggingPrefix    
                } else {
                    Write-EdenBuildError "The local service does not have a public url." $loggingPrefix
                }
            }
            if ($serviceReady -and !$subscriptionsDeployed -and ![string]::IsNullOrEmpty($publicUrl)) {
                Write-EdenBuildInfo "Deploying the event subscrpitions for the local service." $loggingPrefix
                Invoke-EdenCommand "Deploy-ServiceSubscriptionsLocal" $edenEnvConfig $loggingPrefix
                Write-EdenBuildInfo "Finished deploying the event subscrpitions for the local service." $loggingPrefix
                $subscriptionsDeployed = $true
            }
            if (($RunFeatureTests -or $RunFeatureTestsContinuously) -and $subscriptionsDeployed -and $null -eq $testingJob) {
                if ($RunFeatureTestsContinuously) {
                    Write-EdenBuildInfo "Testing the service features continuously." $loggingPrefix
                    $testingJob = Start-EdenCommand  `
                        -EdenCommand "Test-ServiceFeaturesContinuous" `
                        -EdenEnvConfig $edenEnvConfig `
                        -LoggingPrefix $loggingPrefix
                } else { 
                    Write-EdenBuildInfo "Testing the service features." $loggingPrefix
                    Invoke-EdenCommand "Test-ServiceFeaturesLocal" $edenEnvConfig $loggingPrefix
                    Write-EdenBuildInfo "Finished testing the service features." $loggingPrefix
                    Write-EdenBuildInfo "Stopping and removing jobs." $loggingPrefix
                    Write-EdenBuildInfo "Stopping tunnel job." $loggingPrefix
                    $serviceJob | Receive-Job | Write-Verbose
                    $tunnelJob | Receive-Job | Write-Verbose
                    Stop-Job -Id $tunnelJob.Id
                    Write-EdenBuildInfo "Removing tunnel job." $loggingPrefix
                    Remove-Job -Id $tunnelJob.Id -Force
                    Write-EdenBuildInfo "Stopping service job." $loggingPrefix
                    Stop-Job -Id $serviceJob.Id
                    Write-EdenBuildInfo "Removing service job." $loggingPrefix
                    Remove-Job -Id $serviceJob.Id -Force
                    return
                }
            }

            $serviceJob | Receive-Job | Write-Verbose
            $tunnelJob | Receive-Job | Write-Verbose
            if ($testingJob) {
                $testingJob | Receive-Job | Write-Verbose
            }
            Write-Verbose "Sleeping."
            Start-Sleep 1
            # Write-Verbose "Inside: Service Job: $($serviceJob.State)"
            # Write-Verbose "Inside: Tunnel Job: $($tunnelJob.State)"
            # Write-Verbose "Inside: Testing Job: $($testingJob)"
        }

        # Write-Verbose "After: Service Job: $($serviceJob.State)"
        # Write-Verbose "After: Tunnel Job: $($tunnelJob.State)"
        # Write-Verbose "After: Testing Job: $($testingJob.State)"

        $serviceJob | Receive-Job | Write-Verbose
        $tunnelJob | Receive-Job | Write-Verbose
        if ($testingJob) {
            $testingJob | Receive-Job | Write-Verbose
        }

        if ($serviceJob.State -eq "Failed") 
        {
            #TODO: Update to print out stacktrack or script and line number.
            throw "Local service failed to run. Status Message: '$($serviceJob.JobStateInfo.Reason.Message)'"
        }
    
        if ($tunnelJob.State -eq "Failed") 
        {
            #TODO: Update to print out stacktrack or script and line number.
            throw "Local tunnel failed to run. Status Message: '$($tunnelJob.JobStateInfo.Reason.Message)'"
        }
    
        if ($testingJob.State -eq "Failed") 
        {
            #TODO: Update to print out stacktrack or script and line number.
            throw "Continuous feature testing failed to run. Status Message: '$($testingJob.JobStateInfo.Reason.Message)'"
        }
    
        Write-EdenBuildInfo "Stopping the local service." $loggingPrefix

        if ($serviceJob) {
            $serviceJob.StopJob()
            Remove-Job -Id $serviceJob.Id
        }
        if ($tunnelJob.State) {
            $tunnelJob.StopJob()
            Remove-Job -Id $tunnelJob.Id -Force
        }
        if ($testingJob) {
            $testingJob.StopJob()
            Remove-Job -Id $testingJob.Id -Force
        }

        Write-EdenBuildInfo "Finished stopping the local service." $loggingPrefix
    } 
    catch 
    {
        Write-EdenBuildError "$($_ | Out-String)"
        Write-EdenBuildError "Stopping and removing jobs due to exception. Message: '$($_.Exception.Message)'" $loggingPrefix
        $serviceJob.StopJob()
        $serviceJob | Remove-Job -Force
        $tunnelJob.StopJob()
        $tunnelJob | Remove-Job -Force
        if ($testingJob) {
            $testingJob.StopJob()
            $testingJob | Remove-Job -Force
        }
        Write-EdenBuildError "Stopped." $loggingPrefix
    }
}
New-Alias `
    -Name e-hs `
    -Value Start-EdenServiceLocal
