# PSake makes variables declared here available in other scriptblocks
Properties {
    #$ProjectRoot = $ENV:BHProjectPath
    #if (-not $ProjectRoot) {
    #    $ProjectRoot = $PSScriptRoot
    #}

    $Timestamp = Get-Date -UFormat '%Y%m%d-%H%M%S'
    $PSVersion = $PSVersionTable.PSVersion.Major
    $lines = '----------------------------------------------------------------------'

    # Script Analyzer
    [ValidateSet('Error', 'Warning', 'Any', 'None')]
    $ScriptAnalysisFailBuildOnSeverityLevel = 'None'
    $ScriptAnalyzerSettingsPath = "$ENV:BHProjectPath\Build\PSScriptAnalyzerSettings.psd1"

    # Define Folders/Files
    $IncludeFolder = Join-Path -Path $env:BHModulePath -ChildPath 'Include'
    $ConfigFolder = Join-Path -Path $env:BHModulePath -ChildPath 'Config'
    $DocsFolder = Join-Path -Path $env:BHModulePath -ChildPath 'Docs'
    $InitFile = Join-Path -Path $env:BHModulePath -ChildPath 'init.ps1'

    # Staging
    #$StagingFolder = Join-Path -Path $ENV:BHProjectPath -ChildPath 'Staging'
    #$StagingModulePath = Join-Path -Path $StagingFolder -ChildPath $env:BHProjectName
    #$StagingModuleManifestPath = Join-Path -Path $StagingModulePath -ChildPath "$($env:BHProjectName).psd1"

    # Documentation

}
Include -fileNamePathToInclude ".\BuildFunctions.ps1"


# Define top-level tasks
Task 'Default' -depends 'Test'



# Show build variables
Task 'Init' {
    $lines
    Set-Location $ENV:BHProjectPath
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
} #Init

Task 'GoNoGo' {
    $lines
    if ($TaskList -contains 'Deploy') { $Branch = 'master'; $VerifyDeployment = $True }
    elseif ($TaskList -contains 'Build') { $Branch = 'development' }
    else { Return }

    $Results = $Null
    $Results = Test-GoNoGo -Branch $Branch
    Assert -conditionToCheck ($Null -eq $Results) -failureMessage "`n`n$Results"

    if ($VerifyDeployment) {
        $FailureMessage = "`n`n[master] and [development] branches are not even.  Make sure [development] is merged into [master] and up to date."
        Assert -conditionToCheck ((& git rev-parse master) -eq (& git rev-parse development) ) -failureMessage $FailureMessage

        $FailureMessage = "`n`nLast Commit does not match '!deploy'. You must run a successful build first."
        Assert -conditionToCheck ((Get-BuildEnvironment -Path $env:BHProjectPath).CommitMessage -match '!deploy') -failureMessage $FailureMessage
    }
} #GoNoGo


Task 'CheckChangeLog' -depends 'Init' {
    #Verify that change log has been updated before. Fail if it has not been updated since the last build
    $lines
    $ChangeLogPath = Get-Content -Path "$env:BHProjectPath\CHANGELOG.md" -ErrorAction SilentlyContinue
    $FingerprintChangeLogPath = Get-Content -Path "$env:BHProjectPath\Build\fingerprintCL" -ErrorAction SilentlyContinue
    if ($FingerprintChangeLogPath) {
        $FailureMessage = "`n`nCHANGELOG has not changed since the last build"
        Assert -conditionToCheck ($Null -ne (Compare-Object -ReferenceObject $ChangeLogPath -DifferenceObject $FingerprintChangeLogPath)) -failureMessage $FailureMessage
    }
    else {
        $FailureMessage = "`n`nCHANGELOG fingerprint has not been created.  Run the task 'UpdateChangeLog'"
        Assert -conditionToCheck ($True) -failureMessage $FailureMessage

    }
} #CheckChangeLog


Task 'PreBuildAnalyze' -depends 'Init' {
    #TODO: Needs to be evaluated and better understanding of scriptanalyzer is needed
    $lines
    Write-Output "Running PSScriptAnalyzer on Private and Public functions`n"

    $Results = @()
    @(
        "$env:BHProjectPath\$env:BHProjectName\Private"
        "$env:BHProjectPath\$env:BHProjectName\Public"
    ) | ForEach-Object {
        $Results += Invoke-ScriptAnalyzer -Path $_ -Recurse
    }

    $Results | Select-Object 'RuleName', 'Severity', 'ScriptName', 'Line', 'Message' | Format-List
    Assert -conditionToCheck ($Results.Count -eq 0) -failureMessage "`n`nOne or more ScriptAnalyzer issues were found. Fix the issues before Building."
} #PreBuildAnalyze


Task 'CreateConceptualHelp' -depends 'Init' {
    #TODO: Create this and see if parameters can be passed in the build script, or maybe a read host (not idea)
}


Task 'Clean' -depends 'Init' {
    $lines

    $foldersToClean = @(
        $env:BHBuildOutput
    )

    # Remove folders
    foreach ($folderPath in $foldersToClean) {
        Remove-Item -Path $folderPath -Recurse -Force -ErrorAction 'SilentlyContinue'
        New-Item -Path $folderPath -ItemType 'Directory' -Force | Out-String | Write-Verbose
    }
} #Clean


Task 'CompileModule' -depends 'Clean' {
    #Step 1 - Get content of all functions (private and public)
    #Step 2 - Compile functions to single PSM1
    #Step 3 - Copy manifest to BuildOutput
    #STep 4 - Update manifest with exported public functions
    $lines

    # Get public and private function files
    $PrivateFunctions = @( Get-ChildItem -Path "$env:BHModulePath\Private\*.ps1" -Recurse -ErrorAction 'SilentlyContinue' )
    $PublicFunctions = @( Get-ChildItem -Path "$env:BHModulePath\Public\*.ps1" -Recurse -ErrorAction 'SilentlyContinue' )

    # Combine functions into a single .psm1 module

    New-Item -Path "$env:BHBuildOutput\$env:BHProjectName\$env:BHProjectName.psm1" -ItemType File -Force
    @((Get-Content -Path $InitFile) + '') | Add-Content -Path "$env:BHBuildOutput\$env:BHProjectName\$env:BHProjectName.psm1" -Force
    @($publicFunctions + $privateFunctions) | ForEach-Object { ($_ | Get-Content) + '' } | Add-Content -Path "$env:BHBuildOutput\$env:BHProjectName\$env:BHProjectName.psm1" -Force

    # Copy existing manifest
    Copy-Item -Path $env:BHPSModuleManifest -Destination "$env:BHBuildOutput\$env:BHProjectName" -Recurse

    # Add public functions to export in manifest
    $params = @{
        Path              = "$env:BHBuildOutput\$Env:BHProjectName\$Env:BHProjectName.psd1"
        FunctionsToExport = ($PublicFunctions).FullName | ForEach-Object { [io.path]::GetFileNameWithoutExtension($_) }
    }
    Update-ModuleManifest @params

    # Copy other required folders and files
    If (Test-Path $IncludeFolder) { Copy-Item -Path $IncludeFolder -Destination "$env:BHBuildOutput\$env:BHProjectName" -Recurse }
    If (Test-Path $ConfigFolder) { Copy-Item -Path $ConfigFolder -Destination "$env:BHBuildOutput\$env:BHProjectName" -Recurse }
}


Task 'ImportStagingModule' -depends 'CompileModule' {
    $lines
    Try {
        if (Get-Module -name $env:BHProjectName) {
            Remove-Module -name $env:BHProjectName -Force -ErrorAction Stop
        }
        Import-Module -name "$env:BHBuildOutput\$env:BHProjectName\$env:BHProjectName.psd1" -ErrorAction 'Stop' -Force -Scope Global
    }
    Catch {
        Throw "Failed to reload built module $env:BHProjectName"
    }
}


Task 'Analyze' -depends 'ImportStagingModule' {
    $lines
    Write-Output "Running PSScriptAnalyzer on compiled module`n"

    $Results = Invoke-ScriptAnalyzer -Path "$env:BHBuildOutput\$env:BHProjectName" -Settings "$env:BHProjectPath\ScriptAnalyzerSettings.psd1" -Recurse
    $Results | Select-Object 'RuleName', 'Severity', 'ScriptName', 'Line', 'Message' | Format-List

    switch ($ScriptAnalysisFailBuildOnSeverityLevel) {
        'None' {
            return
        }
        'Error' {
            $Message = 'One or more ScriptAnalyzer errors were found. Build cannot continue!'
            Assert -conditionToCheck (($Results | Where-Object { $_.Severity -eq 'Error' }).Count -eq 0) -failureMessage $Message
        }
        'Warning' {
            $Message = 'One or more ScriptAnalyzer warnings were found. Build cannot continue!'
            Assert -conditionToCheck (($Results | Where-Object { $_.Severity -eq 'Warning' -or $_.Severity -eq 'Error' }).Count -eq 0) -failureMessage $Message
        }
        default {
            $Message = 'One or more ScriptAnalyzer issues were found. Build cannot continue!'
            Assert -conditionToCheck ($Results.Count -eq 0) -failureMessage $Message
        }
    }
}


Task 'Test' -depends 'ImportStagingModule' {
    #! This does not test functions in the built module scope.  The test scripts need to know the difference between "UnitTest" vs "BuildTest"
    $lines

    $TestScripts = @()
    $TestScripts += Get-ChildItem -Path "$ENV:BHProjectPath\$env:BHProjectName\Tests\Common\*.Tests.ps1"
    $TestScripts += Get-ChildItem -Path "$ENV:BHProjectPath\$env:BHProjectName\Tests\Unit\*\*.Tests.ps1"
    $MyOptions = @{
        Run    = @{
            Path     = $TestScripts
            PassThru = $True
        }
        Output = @{
            Verbosity = 'Detailed'
        }
    }
    $TestResults = Invoke-Pester -Configuration (New-PesterConfiguration $MyOptions)

    $FailureMessage = "`n`nPester test failed."
    Assert -conditionToCheck ($TestResults.FailedCount -eq 0) -failureMessage $FailureMessage
}


Task 'ExternalHelp' -depends 'CompileModule' {
    #Step 1 - Create Help documentation MD files from comment based help to ..\BuildOutput\Docs
    #Step 2 - Create external help xml file to Output Docs folder
    $lines
    Start-Job {
        Import-Module Platyps
        #Remove-Module $env:BHProjectName -Force -ErrorAction SilentlyContinue
        #Import-Module $env:BHPSModuleManifest -Force -Scope Global
        Import-Module "$env:BHBuildOutput\$env:BHProjectName\$env:BHProjectName.psd1" -Force -Scope Global

        Write-Output "Adding any new markdown help files to: [ $env:BHBuildOutput\$env:BHProjectName\en-US ]`n"
        New-Item -Path "$env:BHBuildOutput" -name 'Docs' -ItemType Directory -ErrorAction SilentlyContinue

        Copy-Item -Path "$env:BHProjectPath\$env:BHProjectName\Docs\*" -Destination "$env:BHBuildOutput\Docs" -Recurse

        New-MarkdownHelp -Module $env:BHProjectName -OutputFolder "$env:BHBuildOutput\Docs" -AlphabeticParamsOrder -UseFullTypeName -ErrorAction SilentlyContinue
        New-ExternalHelp -Path "$env:BHBuildOutput\Docs" -OutputPath $env:BHBuildOutput\$env:BHProjectName\en-US -Force
    } | Receive-Job -Wait
}

#Step the Module Version
Task 'Step' -depends 'Init' {
    $lines
    Import-Module $env:BHPSModuleManifest -Force

    $CommandList = Get-Command -Module $env:BHProjectName

    Write-Output 'Calculating fingerprint for Version Increment'
    $fingerprint = foreach ( $command in $CommandList ) {
        foreach ( $parameter in $command.parameters.keys ) {
            '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
            $command.parameters[$parameter].aliases |
            ForEach-Object { '{0}:{1}' -f $command.name, $_ }
        }
    }

    if ( Test-Path -Path "$env:BHProjectPath\Build\fingerprint" ) {
        $oldFingerprint = Get-Content -Path "$env:BHProjectPath\Build\fingerprint"
    }

    $bumpVersionType = 'Patch'
    Write-Output 'Detecting new features'
    $fingerprint | Where-Object { $_ -notin $oldFingerprint } |
    ForEach-Object { $bumpVersionType = 'Minor'; "  $_" }
    Write-Output 'Detecting breaking changes'
    $oldFingerprint | Where-Object { $_ -notin $fingerprint } |
    ForEach-Object { $bumpVersionType = 'Major'; "  $_" }

    Set-Content -Path "$env:BHProjectPath\Build\fingerprint" -Value $fingerprint

    Write-Output "Bumping Version Type: $bumpVersionType"

    Step-ModuleVersion -Path $env:BHPSModuleManifest -By $bumpVersionType

    #! Be aware this Region uses the same code as compile task.  Consider moving this task and variable declarations as a separate function
    #Region:
    # Copy existing manifest
    Copy-Item -Path $env:BHPSModuleManifest -Destination "$env:BHBuildOutput\$env:BHProjectName" -Recurse

    # Add public functions to export in manifest
    $PublicFunctions = @( Get-ChildItem -Path "$env:BHModulePath\Public\*.ps1" -Recurse -ErrorAction 'SilentlyContinue' )
    $params = @{
        Path              = "$env:BHBuildOutput\$Env:BHProjectName\$Env:BHProjectName.psd1"
        FunctionsToExport = ($PublicFunctions).FullName | ForEach-Object { [io.path]::GetFileNameWithoutExtension($_) }
    }
    Update-ModuleManifest @params
    #EndRegion
}

Task 'UpdateChangeLog' -depends 'Step' {
    $ChangeLogPath = "$env:BHProjectPath\CHANGELOG.md"
    if (-Not (Test-Path -Path $ChangeLogPath)) {
        Write-Error "Change log is missing"
    }
    $ModuleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion
    $Date = Get-Date -Format 'yyyy-MM-dd'
    $ChangeLog = Get-Content $ChangeLogPath
    $ChangeLog = $ChangeLog -replace '\[Unreleased\]', "[Unreleased]`n`n## [$ModuleVersion] - $Date"
    $ChangeLog | Out-File $ChangeLogPath -Force
    Copy-Item -Path $ChangeLogPath -Destination "$env:BHProjectPath\Build\fingerprintCL" -Force
}

# Task 'Release' -Depends 'Clean', 'Test', 'UpdateDocumentation', 'CompileModule', 'CreateBuildArtifact' #'UpdateManifest', 'UpdateTag'
#Task 'Build' -depends 'BuildGoNoGo', 'Step', 'ExternalHelp', 'Analyze', 'BuildTest' {
Task 'Build' -depends 'GoNoGo', 'CheckChangeLog', 'ExternalHelp', 'Analyze', 'Test', 'Step', 'UpdateChangeLog' {
    $lines

    #. "$psscriptroot\NewGitFunctions.ps1" #TODO: consider moving this to a module or somewhere else
    Write-Output "Checking post build modified files"


    $PostBuildModifiedFiles = (Get-expGitStatus).FilePath
    foreach ($ModifiedFile in $PostBuildModifiedFiles) {
        if (-Not ($ModifiedFile -match '^Build\/fingerprint$|^exp\..+\/exp\..+\.psd1$|^CHANGELOG\.md$|^Build\/fingerprintCL$')) {
            Write-Error "There is an unexpected modified file [$ModifiedFile]"
        }
    }

    Write-Output "Adding, committing and pushing post build modified files"
    $ModuleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion
    Write-Output "Git add --all"
    [void](& git add --all)
    [void](& git commit -m "Finalizing build and stepping version [$ModuleVersion]")
    [void](& git commit --allow-empty -m '[!deploy] Build is ready for deployment.')
    [void](& git push)

    Write-Output "Verifying there Git status is clean and the branch is not ahead or behind source"
    if (Get-expGitStatus) { Write-Error "Modified files are present" }
    if (-Not ($Null -eq (Get-expGitAheadBehind).NumberOfCommit)) { Write-Error "Branch is not in sync with source" }

}

Task 'Deploy' -depends 'GoNoGo' {
    $lines

    Write-Output "Deploying"
    $Params = @{
        Path    = "$env:BHProjectPath\Build\deploy.psdeploy.ps1"
        Force   = $true
        Recurse = $false
    }
    Invoke-PSDeploy @Params

    Write-Output "Switching back to branch [development]"
    Start-Sleep -Seconds 3
    & git checkout development

}


<#
# Create a versioned zip file of all staged files
# NOTE: Admin Rights are needed if you run this locally
Task 'CreateBuildArtifact' -Depends 'Init' {
    $lines

    # Create /Release folder
    New-Item -Path $ArtifactFolder -ItemType 'Directory' -Force | Out-String | Write-Verbose

    # Get current manifest version
    try {
        $manifest = Test-ModuleManifest -Path $StagingModuleManifestPath -ErrorAction 'Stop'
        [Version]$manifestVersion = $manifest.Version

    }
    catch {
        throw "Could not get manifest version from [$StagingModuleManifestPath]"
    }

    # Create zip file
    try {
        $releaseFilename = "$($env:BHProjectName)-v$($manifestVersion.ToString()).zip"
        $releasePath = Join-Path -Path $ArtifactFolder -ChildPath $releaseFilename
        Write-Host "Creating release artifact [$releasePath] using manifest version [$manifestVersion]" -ForegroundColor 'Yellow'
        Compress-Archive -Path "$StagingFolder/*" -DestinationPath $releasePath -Force -Verbose -ErrorAction 'Stop'
    }
    catch {
        throw "Could not create release artifact [$releasePath] using manifest version [$manifestVersion]"
    }

    Write-Output "`nFINISHED: Release artifact creation."
}
#>


















# [ARCHIVED] Create new Documentation markdown files
#Task 'UpdateDocumentation' -Depends 'Clean' {
#    $lines
#    Remove-Module $env:BHProjectName -Force -ErrorAction SilentlyContinue
#    Import-Module $env:BHPSModuleManifest -Force -Scope Global
#
#
#
#    Write-Output "Adding any new markdown help files to: [ $env:BHModulePath\Docs ]`n"
#    New-MarkdownHelp -Module $env:BHProjectName -OutputFolder "$env:BHModulePath\Docs" -AlphabeticParamsOrder -UseFullTypeName -ErrorAction SilentlyContinue
#
#    ##Write-Output "Updating any existing markdown help files to: [ $env:BHModulePath\Docs ]`n"
#    ##Update-MarkdownHelp -Path "$env:BHModulePath\Docs" -AlphabeticParamsOrder -UseFullTypeName
#}