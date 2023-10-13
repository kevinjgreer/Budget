function get-Budget {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter()]
        [String]
        $Name
    )

    begin {

    }

    process {
        try {
            $AllBudgets = ConvertFrom-Json -InputObject (Get-Content -Path "$($env:localappdata)\Budget\AllBudgets.json" -Raw -ErrorAction SilentlyContinue)
        }
        Catch {}
        if ($AllBudgets) {
            if ($PSBoundParameters.ContainsKey('Name')) {
                $AllBudgets | Where-Object { $_.Name -eq $Name }
            }
            else {
                $AllBudgets
            }
        }
        else {
            #Write-Warning -Message "No budgets found"
        }
    }

    end {

    }
}