Function New-Budget {
    <#
.SYNOPSIS
Creates a new budget with the specified name and path. The budget is used to manage finances, and this function creates the necessary directory structure, configuration files, and updates the list of all budgets.

.DESCRIPTION
The New-Budget function creates a new budget in the specified location with the given name. It creates a directory structure for the budget, including the main budget directory, subdirectories for accounts, and a configuration file. Additionally, it can set the new budget as the default budget, which is used in various budget-related operations.

.PARAMETER Name
The name of the new budget. This should be a valid folder name and must not contain any invalid characters like '/', ':', '*', '?', '"', '<', or '>'. This parameter is mandatory.

.PARAMETER Path
The path where the new budget directory should be created. It is mandatory and must point to an existing container (directory).

.PARAMETER SetDefault
Indicates whether to set the new budget as the default budget. If a default budget already exists, using this parameter will overwrite it. Use the -Force parameter to overwrite the existing default budget.

.PARAMETER Force
Forces overwriting the default budget if it already exists.

.EXAMPLE
PS C:\> New-Budget -Name "MyMonthlyBudget" -Path "C:\Budgets" -SetDefault
Creates a new budget named "MyMonthlyBudget" in the "C:\Budgets" directory and sets it as the default budget. If a default budget already exists, it will be overwritten.

.EXAMPLE
PS C:\> New-Budget -Name "VacationFund" -Path "D:\Finances\Personal"
Creates a new budget named "VacationFund" in the "D:\Finances\Personal" directory without setting it as the default budget.

.NOTES
File structure:
- The main budget directory: "$Path\$Name"
- Subdirectory for accounts: "$Path\$Name\Accounts"
- Configuration file: "$Path\$Name\BudgetConfig.json"

The function also maintains a list of all budgets in "$($env:LOCALAPPDATA)\Budget\AllBudgets.json".

You can now add income, expenses, and accounts to this budget. Refer to the documentation for more details.
#>

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
            [VOID](New-Item -Path "$Path\$Name\Expense" -ItemType Directory -Force -ErrorAction Stop)
            [VOID](New-Item -Path "$Path\$Name\Income" -ItemType Directory -Force -ErrorAction Stop)
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