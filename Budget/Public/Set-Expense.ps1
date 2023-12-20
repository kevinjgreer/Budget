function Set-Expense {
    [CmdletBinding()]
    param (
        #Parameters necessary to change properties of an expense
        [Parameter(Mandatory)]
        [String]
        $Expense,

        [Parameter()]
        [String]
        $BudgetName,

        [Parameter()]
        [string]
        $NewExpenseName,

        [Parameter()]
        [ValidateSet('Essentials', 'Discretionary', 'Savings', 'Annual', 'Credit', 'Loan', 'Healthcare', 'Subscription', 'Miscellaneous')]
        [String]
        $Category,

        [Parameter()]
        [Decimal]
        $Amount,

        [Parameter()]
        [ValidateRange(1, 12)]
        [Int]
        $Month,

        [Parameter()]
        [ValidateRange(0, 31)]
        [Int]
        $Day,

        [Parameter()]
        [Bool]
        $Active,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [String]
        $Note
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

        $ExpensesToReturn = @()
        $ExpenseList = Get-Expense -BudgetName $Budget.Name
        if ($ExpenseList) {
            $ExpensesToReturn += $ExpenseList
        }

        #TODO: Handle if the expense is not found to set

        if ($PSBoundParameters.ContainsKey('NewExpenseName')) {
            if ($ExpensesToReturn.Expense -Contains $NewExpenseName) {
                Write-Error -Message "Expense $NewExpenseName already exists"
            }
        }

        #$ExpenseToSet = $ExpensesToReturn | Where-Object { $_.Expense -eq $Expense }
        $ExpenseToSet = $ExpensesToReturn | Where-Object { $_.Expense -like "*$Expense*" }
        if (-Not $ExpenseToSet) {
            Write-Error -Message "Expense $Expense does not exist."
            Return
        }
        elseif ($ExpenseToSet.Count -gt 1) {
            Write-Error -Message "Multiple expenses found matching $Expense.  Please specify a more specific expense name."
            Return
        }

        Switch ($ExpenseToSet.Type) {
            'Monthly' {
                if ($PSBoundParameters.ContainsKey('Month')) {
                    Write-Error -Message "Month cannot be specified for Monthly expenses"
                }
                $OutputMonth = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
            }
            'Yearly' {
                $OutputMonth = $Month
            }
            'Quarterly' {
                $Start = $Month
                $Series = @()
                for ($i = 0; $i -lt 4; $i++) {
                    $Series += $Start
                    $Start = ($Start + 3) % 12
                }
                $OutputMonth = $Series

            }
        } #end switch

        if ($PSBoundParameters.ContainsKey('NewExpenseName')) {
            $ExpenseToSet.Expense = $NewExpenseName
        }
        if ($PSBoundParameters.ContainsKey('Amount')) {
            $ExpenseToSet.Amount = $Amount
        }
        if ($PSBoundParameters.ContainsKey('Category')) {
            $ExpenseToSet.Category = $Category
        }
        if ($PSBoundParameters.ContainsKey('Month')) {
            $ExpenseToSet.Month = $OutputMonth
        }
        if ($PSBoundParameters.ContainsKey('Day')) {
            $ExpenseToSet.Day = $Day
        }
        if ($PSBoundParameters.ContainsKey('Active')) {
            $ExpenseToSet.Active = $Active
        }
        if ($PSBoundParameters.ContainsKey('Description')) {
            $ExpenseToSet.Description = $Description
        }
        if ($PSBoundParameters.ContainsKey('Note')) {
            $ExpenseToSet.Note = $Note
        }

        #replace $expenseToSet in $expensesToReturn
        #$ExpensesToReturn = $ExpensesToReturn | Where-Object { $_.Expense -ne $Expense }
        #$ExpensesToReturn.Add($ExpenseToSet)

        #Remove the BudgetAmount property before saving.  This is because the BudgetAmount is added to the expense output when it is returned from Get-Expense for display purposes only.
        #Because the expenses were returned from Get-Expense, the BudgetAmount property was added to the expense object and needs to be removed before saving the expense object to the json file

        #Each $ExpensesToReturn object now has the property BudgetAmount.  This property is added to the object when it is returned from Get-Expense.
        #The property needs to be removed from each object before saving the objects to the json file
        $ExpensesToReturn | ForEach-Object { $_.PSObject.Properties.Remove('BudgetAmount') }
        $ExpensesToReturn | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($Budget.Path)\Expenses\Expenses.json" -Force
    }

    end {

    }
}