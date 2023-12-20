function Find-Transaction {
    [CmdletBinding()]
    param (
        #parameters for the transaction description, type (Withdrawal or Deposit), minimum amount, maximum amount, start date, end date and any other useful parameters
        [Parameter()]
        [String]
        $BudgetName,

        [Parameter()]
        [String]
        $BankName,

        [Parameter()]
        [String]
        $AccountName,

        [Parameter()]
        [String[]]
        $Description = '*',

        [ValidateSet('Withdrawal', 'Deposit', 'All')]
        [Parameter()]
        [String]
        $Type = 'Withdrawal',

        [ValidateScript({
                if ($_ -ge 0 -and $_ -le [decimal]::MaxValue) {
                    $true
                }
                else {
                    throw "Value must be between 0 and [decimal]::MaxValue."
                }
            })]
        [Parameter()]
        [Decimal]
        $MinimumAmount = 0,

        [ValidateScript({
                if ($_ -ge 0 -and $_ -le [decimal]::MaxValue) {
                    $true
                }
                else {
                    throw "Value must be between 0 and [decimal]::MaxValue."
                }
            })]
        [Parameter()]
        [Decimal]
        $MaximumAmount = [decimal]::MaxValue,

        [ValidateScript({ $_ -le (Get-Date) })]
        [Parameter()]
        [DateTime]
        $StartDate = (Get-Date).AddYears(-1),

        [ValidateScript({ $_ -le (Get-Date) })]
        [Parameter()]
        [DateTime]
        $EndDate = (Get-Date)
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

        #Load the ledger file for the account if it exists
        $LedgerPath = "$AccountPath\Ledger.csv"
        if (Test-Path -Path $LedgerPath) {
            $Ledger = Import-Csv -Path $LedgerPath
        }
        else {
            Write-Warning -Message "No ledger file found for $AccountName.  Please import transactions first."
        }

        if ($PSBoundParameters.ContainsKey('Description')) {
            #if the description contains a | then split the description into an array
            #this allows for multiple descriptions to be searched for even if one or more contain a '|'
            #(i.e. 'Target|Walmart', 'Publix' -- This will split into 3 descriptions: 'Target', 'Walmart', 'Publix' )
            if ($Description -match '\|') {
                $Description = $Description -split '\|'
            }
            #for loop to add "* to the beginning and end of each description item"
            for ($i = 0; $i -lt $Description.Count; $i++) {
                $Description[$i] = "*$($Description[$i])*"
            }
        }

        Switch ($BankName) {
            'AdditionFinancial' {
                $MatchTransactionType = switch ($Type) {
                    'Withdrawal' {
                        'Withdrawal'
                    }
                    'Deposit' {
                        'Deposit'
                    }
                    'All' {
                        'Withdrawal|Deposit'
                    }
                }
                #Get all transactions that match the transaction type (Withdrawal, Deposit, or All)
                $AllTransactions = $Ledger | Where-Object { $_.3 -match $MatchTransactionType }
                Foreach ($Transaction in $AllTransactions) {
                    Switch -regex ($Transaction.3) {
                        'Withdrawal' {
                            #WithDrawal amount is a negative number
                            $Amount = [Decimal]($Transaction.Amount) * -1
                            $TransactionType = 'W'
                        }
                        'Deposit' {
                            #Deposit amount is a positive number
                            $Amount = [Decimal]($Transaction.Amount)
                            $TransactionType = 'D'
                        }
                    }
                    $Date = Get-Date ($Transaction.Date)
                    $TransactionDescription = $Transaction.Description
                    foreach ($DescriptionItem in $Description) {
                        if ($Amount -ge $MinimumAmount -and $Amount -le $MaximumAmount -and $Date -ge $StartDate -and $Date -le $EndDate -and $TransactionDescription -like "*$DescriptionItem*") {
                            [PSCustomObject]@{
                                Date        = $Date
                                type        = $TransactionType
                                Amount      = $Amount
                                Description = $TransactionDescription
                            }
                        }
                    }
                }

                #Old code - Delete once new code is thoroughly tested
                ######Switch ($Type) {
                ######    'Withdrawal' {
                ######        $AllTransactions = $Ledger | Where-Object { $_.3 -match 'Withdrawal' }
                ######        #WithDrawal amount is a negative number
                ######        Foreach ($Transaction in $AllTransactions) {
                ######            $Amount = [Decimal]($Transaction.Amount) * -1
                ######            $Date = Get-Date ($Transaction.Date)
                ######            $TransactionDescription = ($Transaction.Description)
                ######            foreach ($DescriptionItem in $Description) {
                ######                if ($Amount -ge $MinimumAmount -and $Amount -le $MaximumAmount -and $Date -ge $StartDate -and $Date -le $EndDate -and $TransactionDescription -like "*$DescriptionItem*") {
                ######                    [PSCustomObject]@{
                ######                        Date        = $Date
                ######                        Type        = 'W'
                ######                        Amount      = $Amount
                ######                        Description = $TransactionDescription
                ######                    }
                ######                }
                ######            }
                ######        }
                ######
                ######    }
                ######    'Deposit' {
                ######        $AllTransactions = $Ledger | Where-Object { $_.3 -match 'Deposit' }
                ######        #Deposit amount is a positive number
                ######        Foreach ($Transaction in $AllTransactions) {
                ######            $Amount = [Decimal]($Transaction.Amount)
                ######            $Date = Get-Date ($Transaction.Date)
                ######            $TransactionDescription = $Transaction.Description
                ######            foreach ($DescriptionItem in $Description) {
                ######                if ($Amount -ge $MinimumAmount -and $Amount -le $MaximumAmount -and $Date -ge $StartDate -and $Date -le $EndDate -and $TransactionDescription -like "*$DescriptionItem*") {
                ######                    [PSCustomObject]@{
                ######                        Date        = $Date
                ######                        Type        = 'D'
                ######                        Amount      = $Amount
                ######                        Description = $TransactionDescription
                ######                    }
                ######                }
                ######            }
                ######        }
                ######    }
                ######    'All' {
                ######        $AllTransactions = $Ledger | Where-Object { $_.3 -match 'Withdrawal|Deposit' }
                ######        #Deposit amount is a positive number
                ######        #WithDrawal amount is a negative number
                ######        Foreach ($Transaction in $AllTransactions) {
                ######            Switch -regex ($Transaction.3) {
                ######                'Withdrawal' {
                ######                    $Amount = [Decimal]($Transaction.Amount) * -1
                ######                    $TransactionType = 'W'
                ######                }
                ######                'Deposit' {
                ######                    $Amount = [Decimal]($Transaction.Amount)
                ######                    $TransactionType = 'D'
                ######                }
                ######            }
                ######            $Date = Get-Date ($Transaction.Date)
                ######            $TransactionDescription = $Transaction.Description
                ######            foreach ($DescriptionItem in $Description) {
                ######                if ($Amount -ge $MinimumAmount -and $Amount -le $MaximumAmount -and $Date -ge $StartDate -and $Date -le $EndDate -and $TransactionDescription -like "*$DescriptionItem*") {
                ######                    [PSCustomObject]@{
                ######                        Date        = $Date
                ######                        type        = $TransactionType
                ######                        Amount      = $Amount
                ######                        Description = $TransactionDescription
                ######                    }
                ######                }
                ######            }
                ######        }
                ######    }
                ######}
            }
            'Chase' {}
            'Discover' {}
            'WellsFargo' {}
            default {
                Write-Error -Message "Bank $BankName is not supported"
                Return
            }
        }
    }

    end {

    }
}