function Remove-Budget {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name
    )

    begin {

    }

    process {
        $AllBudgets = Get-Budget
        $Budget = $AllBudgets | Where-Object { $_.Name -eq $Name }
        if ($Budget) {
            $AllBudgets = $AllBudgets | Where-Object { $_.Name -ne $Name }
            $AllBudgets | ConvertTo-Json | Out-File -Path "$($env:localappdata)\Budget\AllBudgets.json"
        }
        else {
            Write-Error -Message "Budget $Name does not exist"
        }
    }

    end {

    }
}