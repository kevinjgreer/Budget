function Set-Budget {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter()]
        [bool]$SetDefault
    )

    begin {

    }

    process {

        $AllBudgets = Get-Budget
        $Budget = $AllBudgets | Where-Object { $_.Name -eq $Name }
        if ($Budget) {
            $SaveJson = $false
            if ($PSBoundParameters.ContainsKey('SetDefault')) {
                Switch ($SetDefault) {
                    $True {
                        if ($Budget.Default -eq $true) {
                            Write-Warning -Message "Budget $Name is already the default budget"
                        }
                        else {
                            $Budget.Default = $true
                            $AllBudgets | Where-Object { $_.Name -ne $Name } | ForEach-Object { $_.Default = $false }
                            $SaveJson = $true
                        }
                    } #end true
                    $False {
                        if ($Budget.Default -eq $false) {
                            Write-Warning -Message "Budget $Name is already not the default budget"
                        }
                        else {
                            $Budget.Default = $false
                            $SaveJson = $true
                        }
                    } #end false
                }
            }

            if ($SaveJson) {
                $AllBudgets | ConvertTo-Json | Set-Content -Path "$($env:localappdata)\Budget\AllBudgets.json"
            }
        }
        else {
            Write-Error -Message "Budget $Name does not exist"
        }
    }
    end {

    }
}