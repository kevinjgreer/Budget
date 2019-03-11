# USE THIS FILE FOR ADDITIONAL MODULE CODE.
#. $PSScriptRoot\init.ps1

$functionFolders = @('Public', 'Private')
ForEach ($folder in $functionFolders) {
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath) {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'
        ForEach ($function in $functions) {
            Write-Verbose -Message "Importing $($function.BaseName)"
            . $($function.FullName)
        }
    }
}
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1').BaseName
Export-ModuleMember -Function $publicFunctions

$PrivateFunctions = (Get-ChildItem -Path "$PSScriptRoot\Private" -Filter '*.ps1').BaseName
#Export-ModuleMember -Function $PrivateFunctions