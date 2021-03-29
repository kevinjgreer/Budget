function Get-PaidBills {
    [CmdletBinding()]
    param (

        [Parameter()]
        [String]$Path = "C:\users\kgreer\dropbox\budget\Expenses.json",

        [Parameter()]
        [String]$Account = 'C:\users\kgreer\Dropbox\budget\Accounts\AdditionFinancial_47',

        [Parameter()]
        [DateTime]$Date = "$((Get-Date).month)/1/$((Get-Date).Year)"

    )

    begin {
    }

    process {

        $Bills = (ConvertFrom-Json -InputObject (Get-Content -Path $Path -raw)) | Where-Object { $_.Category -match 'Immediate Obligation|Credit|Loan|Subscription'}

        $LedgerCSV = Get-ChildItem -Path $Account -filter '*.csv' | Sort-Object -Descending LastWriteTime | Select-Object -first 1
        $Ledger = Import-Csv -Path $LedgerCSV.FullName | Where-Object { (Get-Date $_.Date) -GE (Get-Date $Date) }

        foreach ($Bill in $Bills) {
            $FoundBill = $False
            foreach ($Entry in $Ledger) {
                if ($Entry.Description -match $Bill.Description) {
                    $FoundBill = $true

                    $Description = $Entry.Description
                    $Amount = $Entry.Amount
                    $BillDate = $Entry.Date
                    [PSCustomObject]@{
                        Bill   = $Bill.Name
                        Paid   = $True
                        #Description = $Description
                        Amount = $Amount
                        Budgeted = $Bill.Budgeted
                        Due = $Bill.Due
                        Date   = $BillDate
                    }
                    break
                }


            }
            if ($FoundBill -eq $False) {
                [PSCustomObject]@{
                    Bill   = $Bill.Name
                    Paid   = $False
                    #Description = $Null
                    Amount = $Null
                    Budgeted = $Bill.Budgeted
                    Due = $Bill.Due
                    Date   = $Null
                }
            }
        }
    }
    End { }

}