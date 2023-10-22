function New-Bank {
    [CmdletBinding()]
    param (
        #TODO: add validation for only banks this supports i.e. AdditionFinancial, Chase, etc.
        [Parameter(Mandatory)]
        [String]$Name,

        [Parameter()]
        [String]$BudgetName
    )

    begin {

    }

    process {
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

        #Create folder with bank name under Accounts folder if it does not exist
        $BankPath = "$($Budget.Path)\Accounts\$Name"
        if (-Not (Test-Path -Path $BankPath)) {
            try {
                $null = New-Item -Path $BankPath -ItemType Directory
            }
            Catch {
                Write-Error -Message "Unable to create bank folder $BankPath"
                Return
            }
        }
    }

    end {

    }
}