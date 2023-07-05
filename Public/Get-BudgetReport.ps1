function Get-BudgetReport {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        #TODO: Show monthly Income
        $AllIncome = Get-Income
        $TotalMonthlyIncome = 0
        Foreach ($Income in $AllIncome) {
            Switch ($Income.Frequency) {
                'bi-Weekly' { $MultiplyBy = 2 }
                'Weekly' { $MultiplyBy = 4 }
                'Monthly' { $MultiplyBy = 1 }
            }
            $TotalMonthlyIncome += ($Income.Amount * $MultiplyBy)

        }

        $AllExpense = Get-Expense | where active -eq $True
        $TotalMonthlyExpense = ($AllExpense.Budgeted | Measure-Object -Sum).Sum

        $FirstHalfMonthExpense = ($AllExpense | Where-Object { $_.Due -In (1..15) } | Select-Object -expand Budgeted | Measure-Object -Sum).Sum
        $SecondHalfMonthExpense = ($AllExpense | Where-Object { $_.Due -In (16..31) } | Select-Object -expand Budgeted | Measure-Object -Sum).Sum
        $NoDueDateExpenses = ($AllExpense | Where-Object { $Null -eq $_.Due } | Select-Object -expand Budgeted | Measure-Object -Sum).Sum



        Write-Host "Monthly Income   : $TotalMonthlyIncome"
        Write-Host "Monthly Expense  : $TotalMonthlyExpense"
        Write-Host "Difference       : $($TotalMonthlyIncome-$TotalMonthlyExpense)"
        Write-Host "`n"

        Write-Output "`nFirst half Month Expenses: $($FirstHalfMonthExpense + ($NoDueDateExpenses/2)) (This includes half of ""No Due Date Expenses"")"
        Write-Output "__________________________"
        $AllExpense | Where-Object { $_.Due -In (1..15) } | Select-Object Name, Category, Due, Budgeted | Sort-Object Due
        Write-Output ""
        Write-Output "Second half Month Expenses: $($SecondHalfMonthExpense + ($NoDueDateExpenses/2)) (This includes half of ""No Due Date Expenses"")"
        Write-Output "`n__________________________"
        $AllExpense | Where-Object { $_.Due -In (16..31) } | Select-Object Name, Category, Due, Budgeted | Sort-Object Due
        Write-Output ""
        Write-Output "No Due Date Expenses: $NoDueDateExpenses"
        Write-Output "__________________________"
        $AllExpense | Where-Object { $Null -eq $_.Due } | Select-Object Name, Category, Due, Budgeted | Sort-Object Category

        Write-Output "`nEmergency Fund: "
        Write-Output "The below represents what the emergency fund should be at 3 months, 6 months, and 1 year based on only 'Imediate Obligations'"
        $TotalImediateObligations = (Get-Expense | Where-Object category -eq 'Immediate Obligation' | Select-Object  -Expand budgeted | Measure-Object -sum).Sum
        Function Emergency {
            param ($Total = $TotalImediateObligations)
            [PSCustomObject]@{
                MonthlyFund = ((Get-Expense | Where-Object { $_.Name -match 'Emergency' }).Budgeted)
                OneMonth    = $Total
                ThreeMonth  = $Total * 3
                SixMonth    = $Total * 6
                OneYear     = $Total * 12

            }
        }
        $Emergency = Emergency
        $Emergency | Format-List
        Write-Output "__________________________`n"


        $AllIncome | Format-Table
        $AllExpense | Sort-Object Category | Format-Table


    }

    end {

    }
}