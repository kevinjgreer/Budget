function Add-Income {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Income,

        [Parameter()]
        [string]
        $BudgetName,

        [Parameter(Mandatory)]
        [decimal]
        $NetAmount,

        [Parameter(Mandatory)]
        [ValidateSet('Weekly', 'Bi-Weekly', 'Monthly', 'Bi-Monthly' , 'Quarterly', 'Annually')]
        [string]
        $Frequency,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [String]
        $Note
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

        $IncomeToReturn = @()
        $IncomeList = Get-Income -BudgetName $Budget.Name
        if ($IncomeList) {
            $IncomeToReturn += $IncomeList
        }

        #Calculate the net amount per month based on Frequency
        switch ($Frequency) {
            'Weekly' {
                $NetMonth = $NetAmount * 4
            }
            'Bi-Weekly' {
                $NetMonth = $NetAmount * 2
            }
            'Monthly' {
                $NetMonth = $NetAmount
            }
            'Bi-Monthly' {
                $NetMonth = $NetAmount / 2
            }
            'Quarterly' {
                $NetMonth = $NetAmount / 3
            }
            'Annually' {
                $NetMonth = $NetAmount / 12
            }
        }


        #Region: Check if income already exists
        if ($EIncomeList.Income -contains $Income) {
            Write-Error -Message "Income $Income already exists.  Please use a different name"
            Return
        }
        #EndRegion

        if (-not (Test-Path -Path "$($Budget.Path)\Income")) {
            [void](New-Item -Path "$($Budget.Path)\Income" -ItemType Directory)
            Write-Warning -Message "No Income directory found.  Creating Income directory"
        }

        #Region: Create income json file or update existing expense json file
        $NewIncome = [PSCustomObject]@{
            Income      = $Income
            NetAmount   = $NetAmount
            Frequency   = $Frequency
            NetMonthly  = $NetMonth
            Description = $Description
            Note        = $Note
        }

        $IncomeToReturn += $NewIncome
        try {
            $IncomeToReturn | ConvertTo-Json -Depth 10 | Out-File -FilePath "$($Budget.Path)\Income\Income.json" -Force -ErrorAction stop
        }
        catch {
            Write-Error -Message "Unable to write to $($Budget.Path)\Income\Income.json"
            Return
        }




    }

    end {

    }
}