Function New-Budget {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String]$Name,

        [Parameter()]
        [String]$Path
    )

    if (-Not (Test-Path $Path\$Name)) {
        New-Item -Path "$Path\$Name" -ItemType Directory -Force
        [PSCustomObject]@{
            Budget      = $Name
            DateCreated = Get-Date
        } | ConvertTo-Json -Depth 1 | Out-File -FilePath "$Path\$Name\BudgetMain_$Name.json"

    }
}