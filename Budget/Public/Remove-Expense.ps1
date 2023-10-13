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


        if ($ExpenseList.Expense -contains $Expense) {
            $ExpenseList -=
        }

        #Get the expense
        $Expense = $Budget.Expenses | Where-Object { $_.Expense -eq $Expense }
        if ($Expense) {
            $Budget.Expenses.Remove($Expense)
            $Budget | ConvertTo-Json | Set-Content -Path "$($env:localappdata)\Budget\$($Budget.Name).json"
        }
        else {
            Write-Error -Message "Expense $Expense does not exist"
        }
    }

    end {

    }
}