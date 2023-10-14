function Remove-Expense {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Expense,

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
        $ExpensesToReturn = @()
        $ExpenseList = Get-Expense -BudgetName $Budget.Name
        if ($ExpenseList) {
            $ExpensesToReturn += $ExpenseList
        }

        #Get the expense

        if ($ExpensesToReturn.Expense -Contains $Expense) {
            $ExpensesToReturn = $ExpensesToReturn | Where-Object { $_.Expense -ne $Expense }
            $ExpensesToReturn | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($Budget.Path)\Expenses\Expenses.json" -Force
        }
        else {
            Write-Error -Message "Expense $Expense does not exist"
        }
    }

    end {

    }
}