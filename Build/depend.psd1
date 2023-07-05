@{
    # Defaults for all dependencies
    PSDependOptions  = @{
        #Target     = 'CurrentUser'
        Parameters = @{
            # Use a local repository for offline support
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
    }

    # Dependency Management modules
    # PackageManagement = '1.2.2'
    # PowerShellGet     = '2.0.1'

    # Common modules
    BuildHelpers     = 'latest'
    Pester           = 'latest'
    #PlatyPS          = 'latest'
    PSDeploy         = 'latest'
    psake            = 'latest'
    PSScriptAnalyzer = 'latest'
    # 'VMware.VimAutomation.Cloud' = '11.0.0.10379994'
}
