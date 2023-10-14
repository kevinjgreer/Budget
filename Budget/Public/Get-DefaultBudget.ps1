function Get-DefaultBudget {
    <#
    .SYNOPSIS
    Gets the default budget.

    .DESCRIPTION
    This function gets the default budget from the list of all budgets. If no default budget is set, it returns an error message.

    .EXAMPLE
    PS C:\> Get-DefaultBudget
    Returns the default budget.

    .NOTES
    Author: Your Name
    Date:   Today's Date
    #>
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