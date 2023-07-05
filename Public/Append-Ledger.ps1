function Append-Ledger {
    [CmdletBinding()]
    param (
        #validate
        [Parameter()]
        [String]$Path,

        [Parameter()]
        [String]$BudgetPath = 'C:\Users\kgreer\OneDrive\Budget',

        [Parameter(Mandatory)]
        [String]$Account
    )

    begin {
    }

    process {
        If (-not $PSBoundParameters.ContainsKey('Path')) {
            Write-Verbose "converting csv file to YNAB format"
            $Path = (get-childitem -Path "$env:USERPROFILE\Downloads" -Filter "CFETransactions*" | Sort-Object -Property LastWriteTime | Select-Object -Last 1).FullName
        }
        $Content = "Date,1,Amount,Description,2,3,4,5,6,7,8,9,10`n" + (get-content -Path $Path -raw)
        $Content | Set-Content -Path $Path -Force



        $CSVData = Import-Csv -Path $Path | Select-Object @{n = 'Date'; e = { ($_.Date).split(' ')[0] } }, Amount, Description
        $i = 0
        ForEach ($item in $CSVData) {
            Add-Member -InputObject $item -MemberType NoteProperty -Name 'number' -Value $i
            $i++
        }

        $CSVData | Export-Csv -Path "$BudgetPath\Accounts\$Account\$(get-date -Format filedatetime)_$Account.csv" -NoTypeInformation -Force
        Remove-item -Path $Path
    }

    end {
    }
}