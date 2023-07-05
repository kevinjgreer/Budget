$token = 'ef1e0626bf1f96df893cba3ba33c150d1ff381a6d0d208587f91ce171c35f246' | ConvertTo-SecureString -AsPlainText -Force

#$MyBudget = Invoke-RestMethod -Uri 'https://api.youneedabudget.com/v1/budgets/903fe831-8e87-48cd-a5e0-a71339d18a69/months/2022-01-01' -Authentication "Bearer" -Token $token -AllowUnencryptedAuthentication
$AllBudget = Invoke-RestMethod -Uri 'https://api.youneedabudget.com/v1/budgets' -Authentication "Bearer" -Token $token -AllowUnencryptedAuthentication
#TODO: input month year and month
$a = Invoke-RestMethod -Uri 'https://api.youneedabudget.com/v1/budgets/903fe831-8e87-48cd-a5e0-a71339d18a69/months/2022-01-01' -Authentication "Bearer" -Token $token -AllowUnencryptedAuthentication

$Categories = $a.data.month.categories
Foreach ($Category in $Categories){
    [PSCustomObject]@{
        Name = $Category.
    }
}



$CurrentBudget = $Budge.data.budgets | Sort-Object last_modified_on -Descending | Select-Object -First 1

$Months = Invoke-RestMethod -Uri 'https://api.youneedabudget.com/v1/budgets/5b709fc7-7956-44a2-bcf1-0045fa4bc65b/months' -Authentication "Bearer" -Token (ConvertTo-SecureString -AsPlainText $key)