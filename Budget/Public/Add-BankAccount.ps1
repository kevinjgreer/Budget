function Add-BankAccount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$Name,

        [Parameter()]
        [String]$BudgetName,

        [Parameter(Mandatory)]
        [String]$BankName

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

        #Verify Bank exists
        $BankPath = "$($Budget.Path)\Accounts\$BankName"
        if (-Not (Test-Path -Path $BankPath)) {
            Write-Error -Message "Bank $BankName does not exist"
            Return
        }

        #Create an Account folder under the bank folder
        $AccountPath = "$BankPath\$Name"
        if (-Not (Test-Path -Path $AccountPath)) {
            $null = New-Item -Path $AccountPath -ItemType Directory
            $null = New-Item -Path "$AccountPath\_NewTransactions" -ItemType Directory
        }

        #Add readme file for instructions on how to use the accounts
        $ReadmePath = "$AccountPath\Readme.txt"
        $ReadmeText = @'
# Add transactions to the _NewTransactions folder
# Run the Import-Transactions.ps1 script to import the transactions
# Run the Get-Transactions.ps1 script to view the transactions

'@


    }

    end {

    }
}