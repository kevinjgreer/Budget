# This Pester Test assumes it has been invoked from Build.ps1
BeforeAll {
    Remove-Module $env:BHProjectName -Force -ErrorAction SilentlyContinue
    Import-Module "$env:BHBuildOutput\$env:BHProjectName\$env:BHProjectName.psd1"
}


Describe "General project validation: $Env:BHProjectName" {

    Context "Verify all PS files are valid PowerShell" {
        $scripts = Get-ChildItem $Env:BHModulePath -Include *.ps1, *.psm1, *.psd1 -Recurse
        $testCase = $scripts | ForEach-Object { @{file = $_ } }
        It "Script <file.Name> should be valid powershell" -TestCases $testCase {
            param($file)

            $file.FullName | Should -Exist

            $contents = Get-Content -Path $file.FullName -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context "Verify unique public and private functions" {
        It "Public and Private functions should be unique" {
            $PrivateFunctions = Get-ChildItem "$Env:BHModulePath\Private" -Exclude '.gitkeep' | Select-Object -ExpandProperty Name
            $PublicFunctions = Get-ChildItem "$Env:BHModulePath\Public" -Exclude '.gitkeep' | Select-Object -ExpandProperty Name
            if ($PrivateFunctions -and $PublicFunctions) {
                (Compare-Object -ReferenceObject $PrivateFunctions -DifferenceObject $PublicFunctions -ExcludeDifferent).InputObject -join ',' | Should -BeNullOrEmpty
            }
        }
    }

    Context "Verify Public and Private file names and respective function match on the first line" {
        $Files = Get-ChildItem "$Env:BHModulePath\Public" -Exclude '.gitkeep'
        $TestCase = $Files | ForEach-Object { @{ScriptFile = $_.Name; Name = ($_.Name).split('.')[0]; Content = (Get-Content $_) } }
        It "[Public] <ScriptFile> contain function name <Name>" -TestCases $TestCase {
            param($Name, $Content)
            $a = Select-String -InputObject $Content[0] -Pattern 'function .+ \{'
            ($a.matches.value).split(' ')[1] | Should -Be $Name
        }

        $Files = Get-ChildItem "$Env:BHModulePath\Private" -Exclude '.gitkeep'
        $TestCase = $Files | ForEach-Object { @{ScriptFile = $_.Name; Name = ($_.Name).split('.')[0]; Content = (Get-Content $_) } }
        It "[Private] <ScriptFile> contain function name <Name>" -TestCases $TestCase {
            param($Name, $Content)
            $a = Select-String -InputObject $Content[0] -Pattern 'function .+ \{'
            ($a.matches.value).split(' ')[1] | Should -Be $Name
        }
    }

    Context "Verify each Public and Private function has a test file" {
        $Functions = Get-ChildItem "$Env:BHModulePath\Public" -Exclude '.gitkeep'
        $TestCase = $Functions | ForEach-Object { @{file = $_ } }

        It "[Public] <file.Name> Should have a unit test file" -TestCases $TestCase {
            param($file)

            $TestFile = ($file.Name).split('.')[0]

            Test-Path -Path "$env:BHModulePath\tests\Unit\Public\$TestFile.tests.ps1" | Should -be $True
        }

        $Functions = Get-ChildItem "$Env:BHModulePath\Private" -Exclude '.gitkeep'
        $TestCase = $Functions | ForEach-Object { @{file = $_ } }

        It "[Private] <file.Name> Should have a unit test file" -TestCases $TestCase {
            param($file)

            $TestFile = ($file.Name).split('.')[0]

            Test-Path -Path "$env:BHModulePath\tests\Unit\Private\$TestFile.tests.ps1" | Should -be $True
        }
    }

    Context "Verify each imported function has proper help" {
        $Functions = (Get-Command -Module $Env:BHProjectName).Name
        Foreach ($Function in $Functions) {
            $TestCase = @{function = $Function; TheHelp = (Get-Help $Function) }

            It "<function> Synopsis Should not be default" -TestCases $TestCase {
                $TheHelp.synopsis | Should -Not -Match "{{ Fill in the Synopsis }}|Short description"
            }
            It "<function> Synopsis Should not be Null or Empty" -TestCases $TestCase {
                $TheHelp.synopsis | Should -Not -BeNullOrEmpty
            }

            It "<function> Description Should not be default" -TestCases $TestCase {
                $TheHelp.description.text | Should -Not -Match "{{ Fill in the Description }}|Long description"
            }
            It "<function> Description Should not be Null or Empty" -TestCases $TestCase {
                $TheHelp.description.text | Should -Not -BeNullOrEmpty
            }

            It "<function> Should have at least one example" -TestCases $TestCase {
                   ($TheHelp.examples.example).Count | Should -BeGreaterOrEqual 1
            }

            It "<function> Example introduction should be 'PS C:\>'" -TestCases $TestCase {
                (($TheHelp).examples.example) | ForEach-Object {
                    $_.introduction.text | Should -Be 'PS C:\>'
                }
            }

            It "<function> Example code Should Match '<function>'" -TestCases $TestCase {
                (($TheHelp).examples.example.code) | ForEach-Object {
                    $_ | Should -Match $function
                }
            }
            It "<function> Example remark Should Not be Null or Empty" -TestCases $TestCase {
                (($TheHelp).examples.example.remarks) | ForEach-Object {
                    $_ | Should -Not -BeNullOrEmpty
                }
            }

            $Parameters = $Null
            $Parameters = (Get-Help $Function).parameters.parameter.Name
            if ($Parameters) {
                $NewTestCase = $Parameters | ForEach-Object {
                    @{
                        FunctionName = $Function
                        Parameter    = $_
                        Description  = ((Get-Help $Function).parameters.parameter | Where-Object Name -EQ $_).Description
                    }
                }

                It "<FunctionName> Param(<Parameter>) Description should not be default" -TestCases $NewTestCase {
                    param($Description)
                    $Description | Should -Not -Match 'Parameter help description|{{ Fill .+ Description }}'


                }
                It "<FunctionName> Param(<Parameter>) Description should not be null or empty" -TestCases $NewTestCase {
                    param($Description)
                    $Description | Should -Not -BeNullOrEmpty


                }

            }

        }#foreach

    }#Context

}#Describe