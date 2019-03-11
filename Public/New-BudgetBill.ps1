Function New-BudgetBill {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String]$Name,

        [Parameter()]
        [String]$NameMatch
    )

    Begin {
        if (-not($env:BudgetPath)) {
            Write-Warning -Message "Enter the path for budget data to load."
            Enter-Budget
        }
    }

    Process {
        Write-Output "ran"
    }

    End {}
}