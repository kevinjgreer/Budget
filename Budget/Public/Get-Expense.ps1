function Get-Expense {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String[]]
        $Expense,

        [Parameter()]
        [String]
        $BudgetName
    )

    begin {

    }

    process {
        #Get all expenses from the budget if a budget name is specified, otherwise get all expenses from the default budget.  If Expense is specified, return only that expense, otherwise return all expenses
        if ($PSBoundParameters.ContainsKey('BudgetName')) {
            $Budget = Get-Budget -Name $BudgetName
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

        #Now get the expenses from the budget
        try {
            $AllExpenses = ConvertFrom-Json -InputObject (Get-Content -Path "$($Budget.Path)\Expenses\Expenses.json" -Raw -ErrorAction SilentlyContinue)
        }
        Catch {}

        if ($AllExpenses) {
            if ($PSBoundParameters.ContainsKey('Expense')) {
                foreach ($Item in $Expense) {
                    $FoundExpenses = $AllExpenses | Where-Object { $_.Expense -like "*$Item*" }
                    foreach ($FoundExpense in $FoundExpenses) {
                        Switch ($FoundExpense.Type) {
                            'Monthly' {
                                $FoundExpense | Add-Member -MemberType NoteProperty -Name 'BudgetAmount' -Value $FoundExpense.Amount
                            }
                            'Quarterly' {
                                $FoundExpense | Add-Member -MemberType NoteProperty -Name 'BudgetAmount' -Value ([math]::Round($FoundExpense.Amount / 3, 2))
                            }
                            'Yearly' {
                                $FoundExpense | Add-Member -MemberType NoteProperty -Name 'BudgetAmount' -Value ([math]::Round($FoundExpense.Amount / 12, 2))
                            }
                        }
                        $FoundExpense
                    }
                }
            }
            else {
                foreach ($FoundExpense in $AllExpenses) {
                    Switch ($FoundExpense.Type) {
                        'Monthly' {
                            $FoundExpense | Add-Member -MemberType NoteProperty -Name 'BudgetAmount' -Value $FoundExpense.Amount
                        }
                        'Quarterly' {
                            $FoundExpense | Add-Member -MemberType NoteProperty -Name 'BudgetAmount' -Value ([math]::Round($FoundExpense.Amount / 3, 2))
                        }
                        'Yearly' {
                            $FoundExpense | Add-Member -MemberType NoteProperty -Name 'BudgetAmount' -Value ([math]::Round($FoundExpense.Amount / 12, 2))
                        }
                    }
                    $FoundExpense
                }
            }
        }
        else {
            #Write-Warning -Message "No expenses found in budget $($Budget.Name)"
        }

    }

    end {

    }
}