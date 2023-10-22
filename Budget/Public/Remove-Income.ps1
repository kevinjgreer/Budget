function Remove-Income {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Income,

        [Parameter()]
        [string]$BudgetName
    )

    begin {

    }

    process {
        #Validate the budget name
        if ($PSBoundParameters.ContainsKey('BudgetName')) {
            $Budget = get-Budget -Name $BudgetName
            if (-Not $Budget) {
                Write-Error -Message "Budget $BudgetName does not exist"
                Return
            }
        }
        else {
            $Budget = Get-DefaultBudget -ErrorAction SilentlyContinue
            if (-Not $Budget) {
                Write-Error -Message "No default budget set.  Please specify a Budget name, run Set-Budget -SetDefault to set a default budget, or New-Budget to create a new budget and set it as the default budget."
                Return
            }
        }


        #This code is all wrong!
        $IncomeToReturn = @()
        $IncomeList = Get-Income -BudgetName $Budget.Name
        if ($IncomeList) {
            $IncomeToReturn += $IncomeList
        }

        #Get the Income

        if ($IncomeToReturn.Income -Contains $Income) {
            $IncomeToReturn = $IncomeToReturn | Where-Object { $_.Income -ne $Income }
            $IncomeToReturn | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($Budget.Path)\Income\Income.json" -Force
        }
        else {
            Write-Error -Message "Income $Income does not exist"
        }
    }

    end {

    }
}