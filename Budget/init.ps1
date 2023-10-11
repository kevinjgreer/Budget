function Get-expInternalModuleName { $MyInvocation.MyCommand.Source }
$paramSetPSFLoggingProvider = @{
    Name         = 'LogFile'
    InstanceName = 'module'
    FilePath     = "$env:LOCALAPPDATA\EXPDevOps\Modules\$(Get-expInternalModuleName)\Logs\$(Get-expInternalModuleName)-%Date%.log"
    FileType     = 'CMTrace'
    Enabled      = $true
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider