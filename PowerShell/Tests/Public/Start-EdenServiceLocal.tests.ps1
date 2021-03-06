$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

#since we match the srs/tests organization this works
$here = $here -replace 'tests', 'Eden'

. "$here\$sut"    

# Import our module to use InModuleScope
Import-Module (Join-Path $PSScriptRoot "../../Eden/Eden.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "../TestUtilities.psm1") -Force

InModuleScope "Eden" {
    Describe "Public/Start-EdenServiceLocal" {
        BeforeEach {
            Mock Get-SolutionName { "TestSolution" }
            Mock Get-ServiceName { "TestService" }
            Set-TestEnvironment
            [System.Collections.ArrayList]$log = @()
            Mock Write-EdenBuildError (Get-BuildInfoErrorBlock $log)
        }
        Context "When executed successfully" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log -LogLimit 8)
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log)
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log -ReturnValueSet @($false,$true)) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                Start-EdenServiceLocal -Verbose
                Assert-Logs $log @(
                    "TestSolution TestService Run TestEnvironment Starting the local service.",
                    "TestSolution TestService Run TestEnvironment Starting the local service job.",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalService job starting.",
                    "TestSolution TestService Run TestEnvironment Starting the public tunnel job.",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalTunnel job starting.",
                    "TestSolution TestService Run TestEnvironment Checking whether the local service is ready.",
                    "TestSolution TestService Run TestEnvironment Mock: Get-LocalServiceHealth TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment The local service failed the health check.",
                    "TestSolution TestService Run TestEnvironment Checking whether the local service is ready.",
                    "TestSolution TestService Run TestEnvironment Mock: Get-LocalServiceHealth TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment The local service passed the health check.",
                    "TestSolution TestService Run TestEnvironment Deploying the event subscrpitions for the local service.",
                    "TestSolution TestService Run TestEnvironment Mock: Deploy-LocalSubscriptions TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment Finished deploying the event subscrpitions for the local service.",
                    "TestSolution TestService Run TestEnvironment Stopping the local service.",
                    "TestSolution TestService Run TestEnvironment Finished stopping the local service."                )
            }
        }
        Context "When executed continuously successfully" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log -LogLimit 8)
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log)
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log -ReturnValueSet @($false,$true)) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                Start-EdenServiceLocal -Continuous -Verbose
                Assert-Logs $log @(
                    "!SKIP!",
                    "!SKIP!",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalServiceContinuous job starting."
                    # Remaining logs ignored.
                )
            }
        }
        Context "When executed with start error" -Tag "Now" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log)
                Mock Start-EdenCommand (Get-StartEdenCommandBlockWithError $log) -ParameterFilter {
                    $EdenCommand -eq "Start-LocalService"
                }
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Start-LocalService"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log -ReturnValueSet @($false,$true)) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                { Start-EdenServiceLocal -Verbose } | Should -Throw
                Assert-LogsContainSequence $log @(
                    "TestSolution TestService Run TestEnvironment Stopping and removing jobs due to exception. Message: 'Local service failed to run. Status Message: 'My Error!''",    
                    "TestSolution TestService Run TestEnvironment Stopped."
                )
            }
        }
        Context "When executed with tunnel error" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log)
                Mock Start-EdenCommand (Get-StartEdenCommandBlockWithError $log) -ParameterFilter {
                    $EdenCommand -eq "Start-LocalTunnel"
                }
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Start-LocalTunnel"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log -ReturnValueSet @($false,$true)) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                { Start-EdenServiceLocal -Verbose } | Should -Throw
                Assert-LogsContainSequence $log @(
                    "TestSolution TestService Run TestEnvironment Stopping and removing jobs due to exception. Message: 'Local tunnel failed to run. Status Message: 'My Error!''",
                    "TestSolution TestService Run TestEnvironment Stopped."
                )
            }
        }
        Context "When executed with health check error" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log)
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log)
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlockWithError $log) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                { Start-EdenServiceLocal -Verbose } | Should -Throw
                Assert-LogsContainSequence $log @(
                    "TestSolution TestService Run TestEnvironment Stopping and removing jobs due to exception. Message: 'My Error!'",
                    "TestSolution TestService Run TestEnvironment Stopped."
                )
            }
        }
        Context "When executed with feature testing" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log)
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log)
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log -ReturnValueSet @($false,$true)) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                Start-EdenServiceLocal -RunFeatureTests -Verbose
                Assert-Logs $log @(
                    "TestSolution TestService Run TestEnvironment Starting the local service.",
                    "TestSolution TestService Run TestEnvironment Starting the local service job.",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalService job starting.",
                    "TestSolution TestService Run TestEnvironment Starting the public tunnel job.",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalTunnel job starting.",
                    "TestSolution TestService Run TestEnvironment Checking whether the local service is ready.",
                    "TestSolution TestService Run TestEnvironment Mock: Get-LocalServiceHealth TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment The local service failed the health check.",
                    "TestSolution TestService Run TestEnvironment Checking whether the local service is ready.",
                    "TestSolution TestService Run TestEnvironment Mock: Get-LocalServiceHealth TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment The local service passed the health check.",
                    "TestSolution TestService Run TestEnvironment Deploying the event subscrpitions for the local service.",
                    "TestSolution TestService Run TestEnvironment Mock: Deploy-LocalSubscriptions TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment Finished deploying the event subscrpitions for the local service.",
                    "TestSolution TestService Run TestEnvironment Testing the service features.",
                    "TestSolution TestService Run TestEnvironment Mock: Test-Features TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment Finished testing the service features.",
                    "TestSolution TestService Run TestEnvironment Stopping and removing jobs.",
                    "TestSolution TestService Run TestEnvironment Stopping the local service.",
                    "TestSolution TestService Run TestEnvironment Finished stopping the local service."
                )
            }
        }
        Context "When executed with feature testing error" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log)
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log)
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth" -and $EdenCommand -ne "Test-Features"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log -ReturnValueSet @($false,$true)) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlockWithError $log) -ParameterFilter {
                    $EdenCommand -eq "Test-Features"
                }
                { Start-EdenServiceLocal -RunFeatureTests -Verbose } | Should -Throw
                Assert-Logs $log @(
                    "TestSolution TestService Run TestEnvironment Starting the local service.",
                    "TestSolution TestService Run TestEnvironment Starting the local service job.",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalService job starting.",
                    "TestSolution TestService Run TestEnvironment Starting the public tunnel job.",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalTunnel job starting.",
                    "TestSolution TestService Run TestEnvironment Checking whether the local service is ready.",
                    "TestSolution TestService Run TestEnvironment Mock: Get-LocalServiceHealth TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment The local service failed the health check.",
                    "TestSolution TestService Run TestEnvironment Checking whether the local service is ready.",
                    "TestSolution TestService Run TestEnvironment Mock: Get-LocalServiceHealth TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment The local service passed the health check.",
                    "TestSolution TestService Run TestEnvironment Deploying the event subscrpitions for the local service.",
                    "TestSolution TestService Run TestEnvironment Mock: Deploy-LocalSubscriptions TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment Finished deploying the event subscrpitions for the local service.",
                    "TestSolution TestService Run TestEnvironment Testing the service features.",
                    "TestSolution TestService Run TestEnvironment Mock With Error: Test-Features TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment Stopping and removing jobs due to exception. Message: 'My Error!'",
                    "TestSolution TestService Run TestEnvironment Stopped."
                )
            }
        }
        Context "When executed with feature testing continuously" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log -LogLimit 8)
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log)
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log -ReturnValueSet @($false,$true)) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                Start-EdenServiceLocal -RunFeatureTestsContinuously -Verbose
                Assert-Logs $log @(
                    "TestSolution TestService Run TestEnvironment Starting the local service.",
                    "TestSolution TestService Run TestEnvironment Starting the local service job.",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalService job starting.",
                    "TestSolution TestService Run TestEnvironment Starting the public tunnel job.",
                    "TestSolution TestService Run TestEnvironment Mock: Start-LocalTunnel job starting.",
                    "TestSolution TestService Run TestEnvironment Checking whether the local service is ready.",
                    "TestSolution TestService Run TestEnvironment Mock: Get-LocalServiceHealth TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment The local service failed the health check.",
                    "TestSolution TestService Run TestEnvironment Checking whether the local service is ready.",
                    "TestSolution TestService Run TestEnvironment Mock: Get-LocalServiceHealth TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment The local service passed the health check.",
                    "TestSolution TestService Run TestEnvironment Deploying the event subscrpitions for the local service.",
                    "TestSolution TestService Run TestEnvironment Mock: Deploy-LocalSubscriptions TestSolution TestService",
                    "TestSolution TestService Run TestEnvironment Finished deploying the event subscrpitions for the local service.",
                    "TestSolution TestService Run TestEnvironment Testing the service features continuously.",
                    "TestSolution TestService Run TestEnvironment Mock: Test-FeaturesContinuously job starting."
                )
            }
        }
        Context "When executed with feature testing continuously that errors" {
            It "Prints the following logs" {
                Mock Write-EdenBuildInfo (Get-BuildInfoErrorBlock $log)
                Mock Start-EdenCommand (Get-StartEdenCommandBlockWithError $log) -ParameterFilter {
                    $EdenCommand -eq "Test-FeaturesContinuously"
                }
                Mock Start-EdenCommand (Get-StartEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Test-FeaturesContinuously"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log) -ParameterFilter {
                    $EdenCommand -ne "Get-LocalServiceHealth"
                }
                Mock Invoke-EdenCommand (Get-InvokeEdenCommandBlock $log -ReturnValueSet @($false,$true)) -ParameterFilter {
                    $EdenCommand -eq "Get-LocalServiceHealth"
                }
                { Start-EdenServiceLocal -RunFeatureTestsContinuously -Verbose } | Should -Throw
                Assert-LogsContainSequence $log @(
                    "TestSolution TestService Run TestEnvironment Stopping and removing jobs due to exception. Message: 'Continuous feature testing failed to run. Status Message: 'My Error!''",
                    "TestSolution TestService Run TestEnvironment Stopped."
                )
            }
        }
    }
}