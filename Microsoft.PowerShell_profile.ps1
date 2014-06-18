##################################Custom Functions##################################
Function Test-RegistryValue
{
    param(
        [Alias("RegistryPath")]
        [Parameter(Position = 0)]
        [String]$Path
        ,
        [Alias("KeyName")]
        [Parameter(Position = 1)]
        [String]$Name
    )

    process
    {
        if (Test-Path $Path)
        {
            $Key = Get-Item -LiteralPath $Path
            if ($Key.GetValue($Name, $null) -ne $null)
            {
                if ($PassThru)
                {
                    Get-ItemProperty $Path $Name
                }
                else
                {
                    $true
                }
            }
            else
            {
                $false
            }
        }
        else
        {
            $false
        }
    }
}

Function Disable-UAC
{
    $EnableUACRegistryPath = "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System"
    $EnableUACRegistryKeyName = "EnableLUA"
    $UACKeyExists = Test-RegistryValue -RegistryPath $EnableUACRegistryPath -KeyName $EnableUACRegistryKeyName
    if ($UACKeyExists)
    {
        Set-ItemProperty -Path $EnableUACRegistryPath -Name $EnableUACRegistryKeyName -Value 0
    }
    else
    {
        New-ItemProperty -Path $EnableUACRegistryPath -Name $EnableUACRegistryKeyName -Value 0 -PropertyType "DWord"
    }
}

##########################################Aliases#########################################################
function subl { &"${Env:ProgramFiles}\Sublime Text 3\sublime_text.exe" $args }

############################Custom Sourcing########################################

# update path to include git
$env:path += ";" + (Get-Item "Env:ProgramFiles(x86)").Value + "\Git\bin"

Import-Module 'C:\Users\pbritton\SkyDrive\Documents\WindowsPowerShell\Modules\bookmarks\bookmarks.psm1'
Set-Alias g Invoke-Bookmark

Set-Bookmark pspath C:\Users\pbritton\SkyDrive\Documents\WindowsPowerShell\
Set-Bookmark ~ C:\Users\pbritton
Set-Bookmark dev C:\Development
Set-Bookmark spintranet "C:\Users\pbritton\Sharepoint Intranet"

# Load Posh-GitHub
. 'C:\Users\pbritton\SkyDrive\Documents\WindowsPowerShell\Modules\Posh-GitHub\Posh-GitHub-Profile.ps1'

# Load posh-git example profile
#. 'C:\Users\pbritton\SkyDrive\Documents\WindowsPowerShell\Modules\posh-git\profile.ps1'


New-PSdrive -name scripts -PSprovider filesystem -root C:\bin\PowerShellScripts


# Load posh-git example profile
. 'C:\Users\pbritton\SkyDrive\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1'


# Load posh-git example profile
. 'C:\Users\pbritton\SkyDrive\Documents\WindowsPowerShell\Modules\PsUrl\profile.example.ps1'

