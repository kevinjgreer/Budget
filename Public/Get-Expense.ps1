function Get-Expense {
    [CmdletBinding()]
    param (

        [Parameter()]
        [String]$Path = "C:\Users\kgreer\OneDrive\budget\Expenses.json"

    )

    begin {}

    process {
        [pscustomobject](ConvertFrom-Json -InputObject (Get-Content -Path 'C:\Users\kgreer\OneDrive\Budget\Expenses.json' -raw))

    }

    end {}
}