function Import-Transaction {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $BudgetName

    )

    begin {

    }

    process {
        #Region: Validate the budget name
        if ($PSBoundParameters.ContainsKey('BudgetName')) {
            $Budget = get-Budget -Name $BudgetName
            if (-Not $Budget) {
                Write-Error -Message "Budget $BudgetName does not exist"
                Return
            }
        }
        else {
            $Budget = Get-DefaultBudget -ErrorAction SilentlyContinue
            if (-Not $Budget) {
                Write-Error -Message "No default budget set.  Please specify a Budget name, run Set-Budget -SetDefault to set a default budget, or New-Budget to create a new budget and set it as the default budget."
                Return
            }
        }
        #EndRegion

        #Get any files that are within the _NewTransactions folder from any bank\account folder
        $TransactionFile = Get-ChildItem -Path "$($Budget.Path)\Accounts\*\*\_NewTransactions\*.*" -ErrorAction SilentlyContinue
        Foreach ($Path in $TransactionFile.FullName) {
            Write-Verbose $Path
            #Get the bank name and account name from the path
            $BudgetPath = $Budget.Path
            $SplitPath = $Path.Replace("$BudgetPath\Accounts\", "").Split('\')
            $BankName = $SplitPath[0]
            $AccountName = $SplitPath[1]
            $FileName = $SplitPath[3]

            #Region: backup the csv file first and main ledger csv file (if it exists)
            $BackupFolder = "$BudgetPath\Accounts\$BankName\$AccountName\Backup"
            if (-not (Test-Path -Path $BackupFolder)) {
                $null = New-Item -Path $BackupFolder -ItemType Directory
            }
            $Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $ArchiveFiles = @()
            $ArchiveFiles += $Path
            if (Test-Path "$BudgetPath\Accounts\$BankName\$AccountName\Ledger.csv") {
                $LedgerFile = "$BudgetPath\Accounts\$BankName\$AccountName\Ledger.csv"
                $ArchiveFiles += $LedgerFile
            }
            Compress-Archive -Path $ArchiveFiles -DestinationPath "$BudgetPath\Accounts\$BankName\$AccountName\Backup\${FileName}_$Date.zip" -Force
            Start-Sleep -Seconds 3
            #EndRegion

            Switch ($BankName) {
                'AdditionFinancial' {
                    #Append the top line of the csv file
                    #TODO: call a cleanup of old backups
                    $Content = "Date,1,Amount,Description,2,3,4,5,6,7,8,9,10`n" + (Get-Content -Path $Path -Raw)
                    $Content | Set-Content -Path $Path -Force

                    #Import the csv file
                    $NewTransactions = Import-Csv -Path $Path
                    #TODO: Get the main ledger csv file if it exists and import it
                    if ($LedgerFile) {
                        $LedgerTransactions = Import-Csv -Path $LedgerFile
                        $a = Compare-Object -ReferenceObject $LedgerTransactions -DifferenceObject $NewTransactions -Property '2' Where-Object { $_.SideIndicator -eq '=>' }
                        $a
                    }
                    else {

                    }


                    #DO I want to be able to convert the csv file for YNAB support and save to another folder with a date/time stamp?

                }
                'Chase' {
                }
                'Discover' {
                }
                'WellsFargo' {
                }
                default {
                    Write-Error -Message "Bank $BankName is not supported"
                    Return
                }
            } #End Switch
        }
    }

    end {

    }
}