function Get-Income {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String[]]
        $Income,

        [Parameter()]
        [String]
        $BudgetName
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

        #Now get the income from the budget
        try {
            $AllIncome = ConvertFrom-Json -InputObject (Get-Content -Path "$($Budget.Path)\Income\Income.json" -Raw -ErrorAction SilentlyContinue)
        }
        Catch {}

        if ($AllIncome) {
            if ($PSBoundParameters.ContainsKey('Income')) {
                foreach ($Item in $Income) {
                    $AllIncome | Where-Object { $_.Income -eq $Item }
                }
            }
            else {
                $AllIncome
            }
        }

    }

    end {

    }
}