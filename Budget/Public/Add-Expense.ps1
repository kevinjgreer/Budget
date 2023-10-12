function Add-Expense {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        #parameter for budget name
        [Parameter(Mandatory)]
        [string]$Budget,

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
        if (-Not (Get-Budget -Name $Budget)) {
            Write-Error -Message "Budget $Budget does not exist"
            Return
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
        [PSCustomObject]@{
            Name        = $Name
            Category    = $Category
            Amount      = $Amount
            type        = $Type
            Month       = $OutputMonth
            Day         = $Day
            Active      = $Active
            Description = $Description
            Note        = $Note
        } #| ConvertTo-Json -Depth 1 | Out-File -FilePath "$($env:LOCALAPPDATA)\Budget\$Budget\Expenses\$Name.json" -Force
    }
    end {

    }
}