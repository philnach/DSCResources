function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )
    
    $configuration = @{
        IsSingleInstance = 'Yes'
        Path = $Path
    }

    Write-Verbose 'Checking if VS Code is installed ...'
    if (Get-VSCodeInstall)
    {
        $configuration.Add('Ensure','Present')
    }
    else
    {
        $configuration.Add('Ensure','Absent')
    }

    $configuration
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        [ValidateSet('Present','Absent')]
        $Ensure = 'Present'
    )
    
    if ($Ensure -eq 'Present')
    {
        Write-Verbose 'Installing VS Code ...'
        $loadInf = '@
[Setup]
Lang=english
Dir=C:\Program Files (x86)\Microsoft VS Code
Group=Visual Studio Code
NoIcons=0
Tasks=desktopicon,addcontextmenufiles,addcontextmenufolders,addtopath
        @'

        $infPath = "${env:TEMP}\load.inf"
        $loadInf | Out-File $infPath
        try
        {
            Start-Process -FilePath $Path -ArgumentList "/VERYSILENT /LOADINF=${infPath}" -Wait
        }
        catch
        {
            Write-Error $_
        }
        
        Write-Verbose -Message 'Testing if VS Code is installed or not ..'
        if (Get-VSCodeInstall)
        {
            Write-Verbose -Message 'VS Code install successful ...'
        }
        else
        {
            Write-Error -Message 'VS Code install failed ...'
        }
    }
    else 
    {
        Write-Verbose 'Uninstalling VS Code ...'
        $vsCodeInstall = Get-VSCodeInstall
        try
        {
            Start-Process -FilePath $($vsCodeInstall.UninstallString) -ArgumentList '/VERYSILENT' -Wait
            Start-Sleep -Seconds 10
        }
        catch
        {
            Write-Error $_
        }
        
        Write-Verbose -Message 'Testing if VS Code is uninstalled or not ..'
        if (Get-VSCodeInstall)
        {
            Write-Error -Message 'VS Code uninstall failed ...'
        }
        else
        {
            Write-Verbose -Message 'VS Code uninstall successful ...'
        }        
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        [ValidateSet('Present','Absent')]
        $Ensure = 'Present'
    )

    Write-Verbose -Message 'Testing if VS Code is installed ...'
    if (Get-VSCodeInstall)
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message 'VS Code is already installed. No action needed.'
            return $true
        }
        else
        {
            Write-Verbose -Message 'VS Code is installed while it should not. It will be removed.'
            return $false
        }
    }
    else
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message 'VS Code is not installed. It will be installed.'
            return $false
        }
        else
        {
            Write-Verbose -Message 'VS Code is not installed. No action needed.'
            return $true
        }
    }
}

Function Get-VSCodeInstall
{
    # First try user based install of VS Code
    $UninstallKey = 'HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*'
    $products = Get-ItemProperty -Path $UninstallKey | Select-Object DisplayName, DisplayVersion, InstallLocation
    if ($products.DisplayName -like 'Microsoft Visual Studio Code*')
    {
        Write-Verbose -Message "Found VS Code user based install in HKCU."
        return $products.Where({$_.DisplayName -like 'Microsoft Visual Studio Code*'})
    }

    # Second try system based install of VS Code
    $UninstallKey = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*'
    $products = Get-ItemProperty -Path $UninstallKey | Select-Object DisplayName, DisplayVersion, InstallLocation
    if ($products.DisplayName -like 'Microsoft Visual Studio Code*')
    {
        Write-Verbose -Message "Found VS Code system based install in HKLM."
        return $products.Where({$_.DisplayName -like 'Microsoft Visual Studio Code*'})
    }

    # TODO support VS Code zip installation 
}

Export-ModuleMember -Function *-TargetResource

