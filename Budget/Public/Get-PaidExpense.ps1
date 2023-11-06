function Get-PaidExpense {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $BudgetName,

        [Parameter()]
        [String]
        $BankName,

        [Parameter()]
        [String]
        $AccountName,

        [ValidateRange(1, 12)]
        [Parameter()]
        [Int]
        $Month = (Get-Date).Month,

        [ValidateScript({ $_ -le (Get-Date).Year })]
        [Parameter()]
        [Int]
        $Year = (Get-Date).Year

    )

    begin {

    }

    process {
        #Region: Validate the budget name
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
        #EndRegion

        #Region: Validate the bank name
        if ($PSBoundParameters.ContainsKey('BankName')) {
            $BankPath = "$($Budget.Path)\Accounts\$BankName"
            if (-Not (Test-Path -Path $BankPath)) {
                Write-Error -Message "Bank $BankName does not exist"
                Return
            }
        }
        else {
            $FindBank = Get-ChildItem -Path "$($Budget.Path)\Accounts" -Directory
            if ($FindBank.Count -eq 1) {
                $BankName = $FindBank.Name
                $BankPath = "$($Budget.Path)\Accounts\$BankName"
            }
            elseif ($BankFolder.Count -gt 1) {
                Write-Error -Message "Multiple banks discovered. Please specify a bank name."
                Return
            }
            else {
                Write-Error -Message "No banks discovered. Please specify a bank name."
                Return
            }
        }
        #EndRegion

        #Region: Validate the account name
        if ($PSBoundParameters.ContainsKey('AccountName')) {
            $AccountPath = "$BankPath\$AccountName"
            if (-Not (Test-Path -Path $AccountPath)) {
                Write-Error -Message "Account $AccountName does not exist"
                Return
            }
        }
        else {
            $FindAccount = Get-ChildItem -Path $BankPath -Directory
            if ($FindAccount.Count -eq 1) {
                $AccountName = $FindAccount.Name
                $AccountPath = "$BankPath\$AccountName"
            }
            elseif ($FindAccount.Count -gt 1) {
                Write-Error -Message "Multiple accounts discovered. Please specify an account name."
                Return
            }
            else {
                Write-Error -Message "No accounts discovered. Please specify an account name."
                Return
            }
        }
        #EndRegion

        #Region: Validate the account name
        if ($PSBoundParameters.ContainsKey('AccountName')) {
            $AccountPath = "$BankPath\$AccountName"
            if (-Not (Test-Path -Path $AccountPath)) {
                Write-Error -Message "Account $AccountName does not exist"
                Return
            }
        }
        else {
            $FindAccount = Get-ChildItem -Path $BankPath -Directory
            if ($FindAccount.Count -eq 1) {
                $AccountName = $FindAccount.Name
                $AccountPath = "$BankPath\$AccountName"
            }
            elseif ($FindAccount.Count -gt 1) {
                Write-Error -Message "Multiple accounts discovered. Please specify an account name."
                Return
            }
            else {
                Write-Error -Message "No accounts discovered. Please specify an account name."
                Return
            }
        }
        #EndRegion

        #$Month should be less than or equal to the current month if the year is the current year
        if ($Year -eq (Get-Date).Year) {
            if ($Month -gt (Get-Date).Month) {
                Write-Error -Message "Month cannot be greater than the current month if the year is the current year"
                Return
            }
        }


        $Expenses = get-expense -BudgetName $Budget.Name | Where-Object { $_.active -eq $true -and $_.Description -ne '' -and $_.Month -contains $Month }

        $StartDate = Get-Date "$Month/$year"
        $EndDate = (Get-Date "$Month/$year").AddMonths(1).AddDays(-1)
        if ($EndDate -gt (Get-Date)) {
            $EndDate = Get-Date
        }
        foreach ($Expense in $Expenses) {
            $PaidTransaction = Find-Transaction -Description $Expense.Description -StartDate $StartDate -EndDate $EndDate
            if ($PaidTransaction) {
                #There could be more than one transaction for the same expense, so loop through each one
                foreach ($Transaction in $PaidTransaction) {
                    $PaidOn = Get-Date $Transaction.Date -Format "MM/dd/yyyy"
                    $Amount = $Transaction.Amount
                    $Difference = $Expense.Amount - $Amount
                    [PSCustomObject]@{
                        'Expense'    = $Expense.Expense
                        'DueDate'    = $Expense.Day
                        'PaidOn'     = $PaidOn
                        'AmountPaid' = $Amount
                        'Amount'     = $Expense.Amount
                        'Difference' = $Difference
                        #'Description' = $Expense.Description
                    }
                }
            } #if ($PaidTransaction)
            else {
                [PSCustomObject]@{
                    'Expense'    = $Expense.Expense
                    'DueDate'    = $Expense.Day
                    'PaidOn'     = $null
                    'AmountPaid' = $null
                    'Amount'     = $Expense.Amount
                    'Difference' = $null
                    #'Description' = $Expense.Description
                }
            } #else ($PaidTransaction)
        } #foreach ($Expense in $Expenses)
    }

    end {

    }
}