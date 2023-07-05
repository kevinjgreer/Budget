function Get-MyBudget {
    #TODO:    Create parameter sets to allow getting 
    #TODO:    All Budgets
    #TODO:    Latest Budget
    #TODO:    Specific budget by id (probably will not need this)
    #TODO:    Specific budget by name (probably will not need this)
    [CmdletBinding()]
    param ()
        
    begin {

    }
    
    process {
        #TODO: use a function to get the token
        $Token = ConvertTo-SecureString -AsPlainText 'KThuou_79pzIVNZ9YJcxaa-qwVCSNBdkKa0wLzprPZQ'

        $param = @{
            Uri = 'https://api.youneedabudget.com/v1/budgets'
            Authentication = "Bearer"
            Token          = $Token
        }

        $BudgetData =Invoke-RestMethod @param
        $AllBudgets = $BudgetData.Data.Budgets

        #Return the latest budget data
        $AllBudgets | Sort-Object -Property 'last_modified_on' -Descending | Select-Object -First 1

        

    }
    
    end {
        
    }
}