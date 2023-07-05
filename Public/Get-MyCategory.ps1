function Get-MyCategory {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter()]
        [String]
        $BudgetID = (Get-MyBudget).id

    )

    begin {

    }

    process {
        #TODO: use a function to get the token
        $Token = ConvertTo-SecureString -AsPlainText 'KThuou_79pzIVNZ9YJcxaa-qwVCSNBdkKa0wLzprPZQ'

        $param = @{
            Uri            = "https://api.youneedabudget.com/v1/budgets/$BudgetID/categories"
            Authentication = "Bearer"
            Token          = $Token
        }
        $CategoryData = Invoke-RestMethod @param
        $AllCategories = $CategoryData.data.category_groups

        Foreach ($CategoryGroup in $AllCategories) {
            Foreach ($Category in $CategoryGroup.categories) {
                #TODO: add calculations here for category


                $GoalTarget = $Category.goal_target
                $PercentComplete = $Category.goal_percentage_complete
                $MonthsToBudget = $Category.goal_months_to_budget
                #$MonthlyAmount = (($GoalTarget / 1000) - ($GoalTarget / 1000) * $PercentComplete) / ($MonthsToBudget - 1)
                $FullCategoryName = ([string]$Category.Name).split('|')
                $CategoryName = $FullCategoryName[0]
                $MonthlyNeed = [String]$FullCategoryName[1]

                [PSCustomObject]@{
                    CategoryGroupName        = $CategoryGroup.name
                    Name                     = $CategoryName
                    hidden                   = $Category.hidden
                    note                     = $Category.note
                    budgeted                 = $Category.budgeted
                    activity                 = $Category.activity
                    balance                  = $Category.balance
                    goal_type                = $Category.goal_type
                    goal_creation_month      = $Category.goal_creation_month
                    goal_target              = $GoalTarget
                    goal_target_month        = $Category.goal_target_month
                    goal_percentage_complete = $PercentComplete
                    goal_months_to_budget    = $MonthsToBudget
                    goal_under_funded        = $Category.goal_under_funded
                    goal_overall_funded      = $Category.goal_overall_funded
                    goal_overall_left        = $Category.goal_overall_left
                    deleted                  = $Category.deleted
                    #MonthlyAmount            = $MonthlyAmount
                    MonthlyNeed              = [Double]$MonthlyNeed.trim()
                }

            }

        }

    }

    end {

    }
}