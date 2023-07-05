function Get-Income {
    [CmdletBinding()]
    param (

        [Parameter()]
        [String]$Path = "C:\Users\kgreer\OneDrive\budget\Income.json"

    )

    begin {}

    process {

        $AllIncome = ConvertFrom-Json -InputObject (Get-Content -Path $Path -Raw)
        Foreach ($Income in $AllIncome) {
            Switch ($Income.Frequency) {
                'bi-Weekly' { $MultiplyBy = 2 }
                'Weekly' { $MultiplyBy = 4 }
                'Monthly' { $MultiplyBy = 1 }
            }
            [PSCustomObject]@{
                Name        = $Income.Name
                Amount      = $Income.Amount
                Monthly     = $Income.Amount * $MultiplyBy
                Frequency   = $Income.Frequency
                Description = $Income.Description

            }

        }

    }
    end {}
}