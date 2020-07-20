[CmdletBinding()]
param(
    $EdenEnvConfig,
    [String] $LoggingPrefix
)

    Write-EdenBuildInfo "Testing the ContentReactor.Audio.sln Solution using the 'Service.Tests/ContentReactor.Audio.Service.Tests'." $LoggingPrefix
    dotnet test ./Service.Tests/ContentReactor.Audio.Service.Tests.csproj `
        --logger "trx;logFileName=testResults.trx" `
        --filter TestCategory!=Automated `
        /p:CollectCoverage=true `
        /p:CoverletOutput=TestResults/ `
        /p:CoverletOutputFormat=lcov `
        /p:Include=`"[ContentReactor.Audio.Service*]*`" `
        /p:Threshold=80 `
        /p:ThresholdType=line `
        /p:ThresholdStat=total 
    Write-EdenBuildInfo "Finished testing the ContentReactor.Audio.sln Solution using the 'Service.Tests/ContentReactor.Audio.Service.Tests'." $LoggingPrefix

    Write-EdenBuildInfo "Copying test results Allure history." $LoggingPrefix
    Copy-Item -Path "./Service.Tests/TestResults/Allure/history" -Destination "./Service.Tests/TestResults/history" -Recurse -Force
    Write-EdenBuildInfo "Finished copying test results Allure history." $LoggingPrefix

    Write-EdenBuildInfo "Generating test results report to './Service.Tests/TestResults/allure'" $LoggingPrefix
    allure generate ./Service.Tests/TestResults/ -o ./Service.Tests/TestResults/Allure --clean
    Write-EdenBuildInfo "Finished generating test results report to './Service.Tests/TestResults/allure'" $LoggingPrefix

    Write-EdenBuildInfo "Generating code coverage reports to './Service.Tests/TestResults/coveragereport'" $LoggingPrefix
    reportgenerator "-reports:./Service.Tests/TestResults/Coverage.info" "-targetdir:Service.Tests/TestResults/coveragereport" -reporttypes:Html
    Write-EdenBuildInfo "Finished generating code coverage reports to './Service.Tests/TestResults/coveragereport'" $LoggingPrefix

    