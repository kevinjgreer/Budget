Function Open-Budget {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String]$Path = "C:\Users\kgreer\Downloads\YNAB Export - My Budget as of 2019-03-10 0803 PM\My Budget as of 2019-03-10 0803 PM - Budget.csv"
    )
    Begin {
        $Month = Get-date -UFormat %b
    }

    Process {
        $BudgetData = Import-Csv -Path $Path | Where-Object {$_.Month -Match $Month -and $_."Category Group" -ne 'Credit Card Payments'}


        ForEach ($Category in $BudgetData) {
            $DueOn = $Null
            $FundOn = $Null
            $SplitCategory = $Category.Category.Split('|')

            if ($SplitCategory[1]) {
                [decimal]$Amount = (($SplitCategory[1]).Trim().Trim('$'))
            }
            else {
                $Amount = 0.00
            }

            if ($SplitCategory[4]) {
                $DueOn = [int32]($SplitCategory[4].Trim('Due '))
                if ($DueOn -LE 5) {
                    $FundOn = $DueOn - 5 + 28
                }
                elseif ($DueOn) {
                    $FundOn = $DueOn - 5
                }
            }


            [PSCustomObject]@{
                Group    = $Category."Category Group"
                Category = $SplitCategory[0]
                Amount   = $Amount
                Method   = $SplitCategory[2]
                Account  = $SplitCategory[3]
                FundOn   = $FundOn
                DueOn    = $DueOn

            }
        }
    }

    End {}

}