function Find-Transaction {
    [CmdletBinding()]
    param (
        #parameters for the transaction description, type (Withdrawl or Deposit), minimum amount, maximum amount, start date, end date and any other useful parameters
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
        [String]
        $Description,

        [ValidateSet('Withdrawl', 'Deposit')]
        [Parameter()]
        [String]
        $Type = 'Withdrawl',

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
            $BankPath = "$($Budget.Path)\Accounts"
            $BankFolders = Get-ChildItem -Path $BankPath -Directory
            if ($BankFolders.Count -eq 1) {
                $BankName = $BankFolders.Name
            }
            elseif ($BankFolders.Count -gt 1) {
                Write-Error -Message "Multiple banks discovered. Please specify a bank name."
                Return
            }
            else {
                Write-Error -Message "No banks discovered. Please specify a bank name."
                Return
            }
        }

        $BankPath = "$($Budget.Path)\Accounts"
        $BankFolders = Get-ChildItem -Path $BankPath -Directory
        if ($BankFolders.Count -eq 1) {
            $BankName = $BankFolders.Name
        }
        elseif (-not $BankName) {
            Write-Error -Message "Multiple banks discovered. Please specify a bank name."
            Return
        }

        if (-not (Test-Path -Path "$BankPath\$BankName")) {
            Write-Error -Message "Bank $BankName does not exist"
            Return
        }
        #EndRegion

        #Region: Validate the account name
        if ($PSBoundParameters.ContainsKey('AccountName')) {
            $AccountPath = "$BankPath\$BankName\$AccountName"
            if (-Not (Test-Path -Path $AccountPath)) {
                Write-Error -Message "Account $AccountName does not exist"
                Return
            }
        }
        else {
            $AccountPath = "$BankPath\$BankName"
            $AccountFolders = Get-ChildItem -Path $AccountPath -Directory
            if ($AccountFolders.Count -eq 1) {
                $AccountName = $AccountFolders.Name
            }
            elseif ($AccountFolders.Count -gt 1) {
                Write-Error -Message "Multiple accounts discovered. Please specify an account name."
                Return
            }
            else {
                Write-Error -Message "No accounts discovered. Please specify an account name."
                Return
            }
        }




        ##$AccountPath = "$BankPath\$BankName"
        ##$AccountFolders = Get-ChildItem -Path $AccountPath -Directory
        ##if ($AccountFolders.Count -eq 1) {
        ##    $AccountName = $AccountFolders.Name
        ##}
        ##elseif (-not $AccountName) {
        ##    Write-Error -Message "Multiple accounts discovered. Please specify an account name."
        ##    Return
        ##}
        #EndRegion

        $Description
        $Type
        $MinimumAmount
        $MaximumAmount
        $StartDate
        $EndDate

    }

    end {

    }
}