function Get-DefaultBudget {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {
        #Get the Default Budget
        $AllBudgets = Get-Budget
        $DefaultBudget = $AllBudgets | Where-Object { $_.Default -eq $true }
        if ($DefaultBudget) {
            $DefaultBudget
        }
        else {
            Write-Error -Message "No default budget set.  Use Set-Budget -SetDefault to set a default budget, or New-Budget to create a new budget and set it as the default budget."
        }
    }

    end {

    }
}