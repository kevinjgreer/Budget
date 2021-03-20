function Get-PaidBills {
    [CmdletBinding()]
    param (

        [Parameter()]
        [String]$Path = "C:\users\kgreer\dropbox\budget\Bills.json",

        [Parameter()]
        [String]$Account = 'C:\users\kgreer\Dropbox\budget\Accounts\AdditionFinancial_47',

        [Parameter()]
        [DateTime]$Date = "$((Get-Date).month)/1/$((Get-Date).Year)"

    )

    begin {
    }

    process {

        $Bills = ConvertFrom-Json -InputObject (Get-Content -Path $Path -raw)

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
                        Bill        = $Bill.Bill
                        Description = $Description
                        Amount      = $Amount
                        Date        = $BillDate
                    }
                    break
                }


            }
            if ($FoundBill -eq $False) {
                [PSCustomObject]@{
                    Bill        = $Bill.Bill
                    Description = $Null
                    Amount      = $Null
                    Date        = $Null
                }
            }
        }
    }
    End { }

}