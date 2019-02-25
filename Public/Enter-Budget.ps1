Function Enter-Budget {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$Path
    )

    if (-Not (Test-Path $Path)) {
        Write-Warning -Message "Budget path not found: $Path"
    }
    Else {
        $MainBudget = Get-childitem -Path $Path -Filter 'BudgetMain_1*.json'
        if ($MainBudget) {
            $env:BudgetPath = $Path
        }
        else {
            Write-Warning -Message "Main Budget JSON file not found."
        }
    }
}