function Convert-CSVAdditionFinancial {
    [CmdletBinding()]
    param (
        #validate
        [Parameter()]
        [String]$Path
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
        Import-Csv -Path $Path | Select-Object @{n = 'Date'; e = { ($_.Date).split(' ')[0] } }, Amount, Description | Export-Csv -Path "$(Split-Path -Path $Path -Parent)\ReadyforYNAB.csv" -NoTypeInformation -Force
        Remove-item -Path $Path
        Rename-Item -Path "$(Split-Path -Path $Path -Parent)\ReadyforYNAB.csv" -NewName "$(Split-Path -Path $Path -Leaf)"
    }

    end {
    }
}