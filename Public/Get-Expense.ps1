function Get-Expense {
    [CmdletBinding()]
    param (

        [Parameter()]
        [String]$Path = "C:\users\kgreer\dropbox\budget\Expenses.json"

    )
    
    begin {}
    
    process {
        [pscustomobject](ConvertFrom-Json -InputObject (Get-Content -Path 'C:\Users\kgreer\Dropbox\Budget\Expenses.json' -raw))    

    }
    
    end {}
}