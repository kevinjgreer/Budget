Function New-Budget {
    [CmdletBinding()]
    Param(
        #Must be a valid foldername
        [ValidatePattern("^[^\/:*?""<>|]+?$")]
        [Parameter(Mandatory)]
        [String]$Name,

        [ValidateScript ({ Test-Path $_ -PathType Container })]
        [Parameter(Mandatory)]
        [String]$Path,

        [Parameter()]
        [Switch]$SetDefault,

        [Parameter()]
        [Switch]$Force
    )

    Begin {}
    Process {

        $BudgetsToReturn = @()
        $BudgetList = Get-Budget
        if ($BudgetList) {
            $BudgetsToReturn += $BudgetList
        }

        #Region: Check if budget already exists, or if the path is within another budget path
        if ($BudgetList.Name -contains $Name) {
            Write-Error -Message "Budget $Name already exists.  Please use a different name"
            Return
        }
        if ($BudgetList.Path -contains $Path) {
            Write-Error -Message "Budget path $Path already exists.  Please use a different path"
            Return
        }
        foreach ($item in $BudgetList) {
            if ($Path -like "$($item.Path)\*") {
                Write-Error -Message "The path $Path is within another budget path $($item.Path).  Please use a different path"
                Return
            }
        }
        #EndRegion


        #Region: Set default budget
        if ($PSBoundParameters.ContainsKey('SetDefault')) {
            $DefaultBudget = $BudgetList | Where-Object { $_.Default -eq $true }
            if ($DefaultBudget) {
                #Default budget already exists, set it to false only if -Force is used
                if ($PSBoundParameters.ContainsKey('Force')) {
                    $DefaultBudget.Default = $false
                }
                else {
                    Write-Error -Message "Default budget already exists.  Use -Force to overwrite"
                    Return
                }
                $DefaultBudget.Default = $false
            }
            $SetDefault = $true
        }
        else {
            $SetDefault = $false
        }
        #EndRegion


        #Region: Create budget directory and subdirectories
        try {
            [VOID](New-Item -Path "$Path\$Name" -ItemType Directory -Force -ErrorAction Stop)
            [VOID](New-Item -Path "$Path\$Name\Accounts" -ItemType Directory -Force -ErrorAction Stop)
        }
        Catch {
            Write-Error -Message "Failed to create directory. $($_.Exception.Message)"
            Return
        }
        #EndRegion


        #Region: Create budget config file
        [PSCustomObject]@{
            Budget      = $Name
            DateCreated = Get-Date
            Default     = [bool]$SetDefault
        } | ConvertTo-Json -Depth 1 | Out-File -FilePath "$Path\$Name\BudgetConfig.json"
        #EndRegion


        #Region: Add budget properties to AllBudgets.json, Create AllBudgets.json and path if it doesn't exist
        try {
            $BudgetsToReturn += [PSCustomObject]@{
                Name        = $Name
                Path        = "$Path\$Name"
                DateCreated = (Get-Date)
                Default     = [bool]$SetDefault
            }

            If (-Not (Test-Path "$($env:LOCALAPPDATA)\Budget" -PathType Container)) {
                New-Item -Path "$($env:LOCALAPPDATA)\Budget" -ItemType Directory -ErrorAction Stop
            }
            $BudgetsToReturn | ConvertTo-Json -Depth 1 -ErrorAction Stop | Out-File -FilePath "$($env:LOCALAPPDATA)\Budget\AllBudgets.json" -Force -ErrorAction Stop
        }
        Catch {
            Write-Error -Message "Failed to create AllBudgets.json. $($_.Exception.Message)"
            Return
        }
        #EndRegion

        #TODO: Write about and function docs
        Write-Host "$Name budget has been created in $Path.  You will need to add income, expenses, and accounts.  See documentation."

    }
    End {}

}