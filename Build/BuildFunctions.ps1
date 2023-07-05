function Get-expGitStatus {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {
        $GitOutput = & git status --porcelain
        if ($GitOutput) {
            Foreach ($item in $GitOutput) {
                $StatusID = $item.substring(0, 2).trim()
                Switch ($StatusID) {
                    '??' { $Status = 'Untracked' }
                    'M' { $Status = 'Modified' }
                    'A' { $Status = 'Added' }
                    'D' { $Status = 'Deleted' }
                }
                $FilePath = $item.substring(3)

                [PSCustomObject]@{
                    StatusID = $StatusID
                    Status   = $Status
                    FilePath = $FilePath
                }
            }
        }
    }

    end {

    }
}

function Get-expGitAheadBehind {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {
        $Status = & git status --ahead-behind

        $Branch = $Status[0].substring(10)

        Switch -regex ($Status[1]) {
            'Ahead' { $AheadBehind = 'Ahead' }
            'Behind' { $AheadBehind = 'Behind' }
        }

        $NumOfCommit = $Status[1].split('''')[-1].trim().split(' ')[1]

        [PSCustomObject]@{
            Branch         = $Branch
            AheadBehind    = $AheadBehind
            NumberOfCommit = $NumOfCommit
        }


    }

    end {

    }
}


function Test-GoNoGo {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [String]
        $Branch
    )

    begin {

    }

    process {
        $GitAheadBehind = Get-expGitAheadBehind
        if ($GitAheadBehind.Branch -ne $Branch) {
            Return "Task cannot continue on branch [$($GitAheadBehind.Branch)]. Switch to branch [$Branch]"
        }

        if (-Not ($Null -eq $GitAheadBehind.NumberOfCommit)) {
            Return "Branch [$($GitAheadBehind.Branch)] is not in sync with Origin."
        }

        $GitStatus = Get-expGitStatus
        if ($GitStatus) {
            Return "There are uncommitted changes."
        }
    }

    end {

    }
}
