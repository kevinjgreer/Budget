function Set-Income {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Income,

        [Parameter()]
        [string]$NewIncomeName,

        [Parameter()]
        [string]$BudgetName,

        [Parameter(Mandatory)]
        [decimal]$NetAmount,

        [Parameter()]
        [ValidateSet('Weekly', 'Bi-Weekly', 'Monthly', 'Bi-Monthly' , 'Quarterly', 'Annually')]
        [string]$Frequency,

        [Parameter()]
        [String]$Description,

        [Parameter()]
        [String]$Note
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

        $IncomesToReturn = @()
        $IncomeList = Get-Income -BudgetName $Budget.Name
        if ($IncomeList) {
            $IncomesToReturn += $IncomeList
        }

        $IncomeToSet = $IncomesToReturn | Where-Object { $_.Income -eq $Income }
        if (-Not $IncomeToSet) {
            Write-Error -Message "Income $Income does not exist"
            Return
        }

        if ($PSBoundParameters.ContainsKey('NewIncomeName')) {
            if ($IncomesToReturn.Income -Contains $NewIncomeName) {
                Write-Error -Message "Income $NewIncomeName already exists"
                Return
            }
            else {
                $IncomeToSet.Income = $NewIncomeName
            }
        }
        if ($PSBoundParameters.ContainsKey('NetAmount')) {
            $IncomeToSet.NetAmount = $NetAmount
        }
        if ($PSBoundParameters.ContainsKey('Frequency')) {
            $IncomeToSet.Frequency = $Frequency
        }
        if ($PSBoundParameters.ContainsKey('Description')) {
            $IncomeToSet.Description = $Description
        }
        if ($PSBoundParameters.ContainsKey('Note')) {
            $IncomeToSet.Note = $Note
        }

        #Calculate the net amount per month based on Frequency if NetAmount or Frequency is specified
        if ($PSBoundParameters.ContainsKey('NetAmount') -or $PSBoundParameters.ContainsKey('Frequency')) {
            switch ($IncomeToSet.Frequency) {
                'Weekly' {
                    $IncomeToSet.NetMonthly = $IncomeToSet.NetAmount * 4
                }
                'Bi-Weekly' {
                    $IncomeToSet.NetMonthly = $IncomeToSet.NetAmount * 2
                }
                'Monthly' {
                    $IncomeToSet.NetMonthly = $IncomeToSet.NetAmount
                }
                'Bi-Monthly' {
                    $IncomeToSet.NetMonthly = $IncomeToSet.NetAmount / 2
                }
                'Quarterly' {
                    $IncomeToSet.NetMonthly = $IncomeToSet.NetAmount / 3
                }
                'Annually' {
                    $IncomeToSet.NetMonthly = $IncomeToSet.NetAmount / 12
                }
            }
        }

        $IncomeToSet | ConvertTo-Json -Depth 10 | Set-Content -Path "$($Budget.Path)\Income\Income.json" -Force
    }

    end {

    }
}