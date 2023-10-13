function Add-Expense {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Expense,

        #parameter for budget name
        [Parameter()]
        [string]$BudgetName,

        [ValidateSet('Essentials', 'Discretionary', 'Savings', 'Annual', 'Debt', 'Healthcare', 'Subscriptions', 'Miscellaneous')]
        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [decimal]$Amount,

        [ValidateSet('Monthly', 'Yearly', 'Quarterly')]
        [Parameter(Mandatory)]
        [string]$Type,

        [ValidateRange(1, 12)]
        [Parameter()]
        [int]$Month,

        [ValidateRange(1, 31)]
        [Parameter()]
        [int]$Day,

        [Parameter()]
        [Bool]$Active = $true,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [string]$Note
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

        Switch ($Type) {
            'Monthly' {
                if ($PSBoundParameters.ContainsKey('Month')) {
                    Write-Error -Message "Month cannot be specified for Monthly expenses"
                }
                if (-not $PSBoundParameters.ContainsKey('Day')) {
                    Write-Error -Message "Day must be specified for Monthly expenses"
                }
                $OutputMonth = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
            }
            'Yearly' {
                if (-not $PSBoundParameters.ContainsKey('Month')) {
                    Write-Error -Message "Month must be specified for Yearly expenses"
                }
                if (-not $PSBoundParameters.ContainsKey('Day')) {
                    Write-Error -Message "Day must be specified for Yearly expenses"
                }
                $OutputMonth = $Month
            }
            'Quarterly' {
                if (-not $PSBoundParameters.ContainsKey('Month')) {
                    Write-Error -Message "First Month in series must be specified for Quarterly expenses"
                }


                if (-not $PSBoundParameters.ContainsKey('Day')) {
                    Write-Error -Message "Day must be specified for Quarterly expenses"
                }
                $Start = $Month
                $Series = @()
                for ($i = 0; $i -lt 4; $i++) {
                    $Series += $Start
                    $Start = ($Start + 3) % 12
                }
                $OutputMonth = $Series

            }
        }


        $ExpensesToReturn = @()
        $ExpenseList = Get-Expense -BudgetName $Budget.Name
        if ($ExpenseList) {
            $ExpensesToReturn += $ExpenseList
        }

        #Region: Check if expense already exists
        if ($ExpenseList.Expense -contains $Expense) {
            Write-Error -Message "Expense $Expense already exists.  Please use a different name"
            Return
        }
        #EndRegion


        if (-not (Test-Path -Path "$($Budget.Path)\Expenses")) {
            [void](New-Item -Path "$($Budget.Path)\Expenses" -ItemType Directory)
            Write-Warning -Message "No Expenses directory found.  Creating Expenses directory"
        }

        #Region: Create expense json file or update existing expense json file
        $NewExpense = [PSCustomObject]@{
            Expense     = $Expense
            Category    = $Category
            Amount      = $Amount
            type        = $Type
            Month       = $OutputMonth
            Day         = $Day
            Active      = $Active
            Description = $Description
            Note        = $Note
        }

        $ExpensesToReturn += $NewExpense
        $ExpensesToReturn | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($Budget.Path)\Expenses\Expenses.json" -Force














    }
    end {

    }
}