# We're not using Requires because it just gets in the way on PSv2
#!Requires -Modules ModuleInfo, LocalStorage

# FULL # BEGIN FULL: Don't include this in the installer script
$PoshCodeModuleRoot = Get-Variable PSScriptRoot -ErrorAction SilentlyContinue | ForEach-Object { $_.Value }
if(!$PoshCodeModuleRoot) {
  $PoshCodeModuleRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

. $PoshCodeModuleRoot\Constants.ps1
# FULL # END FULL


########################################################################
## Copyright (c) 2013 by Joel Bennett, all rights reserved.
## Free for use under MS-PL, MS-RL, GPL 2, or BSD license. Your choice. 
########################################################################
## Configuration.psm1 defines the Get/Set functionality for ConfigData
## It also includes Get-SpecialFolder for resolving special folder paths
$Script:SpecialFolderNames = @([System.Environment+SpecialFolder].GetFields("Public,Static") | ForEach-Object { $_.Name }) + @("PSHome") | Sort-Object

function Get-SpecialFolder {
  #.Synopsis
  #   Gets the current value for a well known special folder
  [CmdletBinding()]
  param(
    # The name of the Path you want to fetch (supports wildcards).
    #  From the list: AdminTools, ApplicationData, CDBurning, CommonAdminTools, CommonApplicationData, CommonDesktopDirectory, CommonDocuments, CommonMusic, CommonOemLinks, CommonPictures, CommonProgramFiles, CommonProgramFilesX86, CommonPrograms, CommonStartMenu, CommonStartup, CommonTemplates, CommonVideos, Cookies, Desktop, DesktopDirectory, Favorites, Fonts, History, InternetCache, LocalApplicationData, LocalizedResources, MyComputer, MyDocuments, MyMusic, MyPictures, MyVideos, NetworkShortcuts, Personal, PrinterShortcuts, ProgramFiles, ProgramFilesX86, Programs, PSHome, Recent, Resources, SendTo, StartMenu, Startup, System, SystemX86, Templates, UserProfile, Windows
    [ValidateScript({
      $Name = $_
      $Names = 
      if($Script:SpecialFolderNames -like $Name) {
        return $true
      } else {
        throw "Cannot convert Path, with value: `"$Name`", to type `"System.Environment+SpecialFolder`": Error: `"The identifier name $Name is noe one of $($Names -join ', ')"
      }
    })]
    [String]$Path = "*",

    # If set, returns a hashtable of folder names to paths
    [Switch]$Value
  )

  $Names = $Script:SpecialFolderNames -like $Path
  if(!$Value) {
    $return = @{}
  }

  foreach($name in $Names) {
    $result = $(
      if($name -eq "PSHome") {
        $PSHome
      } else {
        [Environment]::GetFolderPath($name)
      }
    )
    if($result) {
      if($Value) {
        Write-Output $result
      } else {
        $return.$name = $result
      }
    }
  }
  if(!$Value) {
    Write-Output $return
  }
}

function Select-ModulePath {
   #.Synopsis
   #   Interactively choose (and validate) a folder from the Env:PSModulePath
   [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
   param(
      # The folder to install to. This folder should be one of the ones in the PSModulePath, NOT a subfolder.
      $InstallPath
   )
   end {
      $ChoicesWithHelp = @()
      [Char]$Letter = "D"
      $default = -1
      $index = -1
      $common = -1
      #  Suppress error when running in remote sessions by making sure $PROFILE is defined
      if(!$PROFILE) { $PROFILE = Join-Path (Get-SpecialFolder MyDocuments) "WindowsPowerShell\Profile.ps1" }
      switch -Wildcard ($Env:PSModulePath -split ";" | ? {$_}) {
         "${PSHome}*" {
            ##### We do not support installing to the System location. #####
            #$index++
            #$ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription "S&ystem", $_
            continue
         }
         "$(Split-Path $PROFILE)*" {
            $index++
            $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription "&Profile", $_
            $default = $index
            continue
         }
         "$(Join-Path ([Environment]::GetFolderPath("ProgramFiles")) WindowsPowerShell\Modules*)" {
            $index++
            $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription $(if($common -lt 0){"&Common"}elseif($common -lt 1){"C&ommon"}elseif($common -lt 2){"Co&mmon"}else{"Commo&n"}), $_
            $common++
            if($Default -lt 0){$Default = $index}
            continue
         }
         "$(Join-Path ([Environment]::GetFolderPath("ProgramFiles")) Microsoft\Windows\PowerShell\Modules*)" {
            $index++
            $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription $(if($common -lt 0){"&Common"}elseif($common -lt 1){"C&ommon"}elseif($common -lt 2){"Co&mmon"}else{"Commo&n"}), $_
            $common++
            if($Default -lt 0){$Default = $index}
            continue
         }
         "$(Join-Path ([Environment]::GetFolderPath("CommonProgramFiles")) Modules)*" {
            $index++
            $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription $(if($common -lt 0){"&Common"}elseif($common -lt 1){"C&ommon"}elseif($common -lt 2){"Co&mmon"}else{"Commo&n"}), $_
            $common++
            if($Default -lt 0){$Default = $index}
            continue
         }
         "$(Join-Path ([Environment]::GetFolderPath("CommonDocuments")) Modules)*" {
            $index++
            $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription $(if($common -lt 0){"&Common"}elseif($common -lt 1){"C&ommon"}elseif($common -lt 2){"Co&mmon"}else{"Commo&n"}), $_
            $common++
            if($Default -lt 0){$Default = $index}
            continue
         }
         "$([Environment]::GetFolderPath("MyDocuments"))*" { 
            $index++
            $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription "&MyDocuments", $_
            if($Default -lt 0){$Default = $index}
            continue
         }
         default {
            $index++
            $Key = $_ -replace [regex]::Escape($Env:USERPROFILE),'~' -replace "((?:[^\\]*\\){2}).+((?:[^\\]*\\){2})",'$1...$2'
            $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription "&$Letter $Key", $_
            $Letter = 1 + $Letter
            continue
         }
      }
      # Let's make sure they have at least one of the "Common" locations:
      if($common -lt 0) {
         $index++
         $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription "&Common", (Join-Path ([Environment]::GetFolderPath("ProgramFiles")) WindowsPowerShell\Modules)
      }
      # And we always offer the "Other" location:
      $index++
      $ChoicesWithHelp += New-Object System.Management.Automation.Host.ChoiceDescription "&Other", "Type in your own path!"
   
      while(!$InstallPath -or !(Test-Path $InstallPath)) {
         if($InstallPath -and !(Test-Path $InstallPath)){
            if($PSCmdlet.ShouldProcess(
               "Verifying module install path '$InstallPath'", 
               "Create folder '$InstallPath'?", 
               "Creating Module Install Path" )) {
      
               $null = New-Item -Type Directory -Path $InstallPath -Force -ErrorVariable FailMkDir
            
               ## Handle the error if they asked for -Common and don't have permissions
               if($FailMkDir -and @($FailMkDir)[0].CategoryInfo.Category -eq "PermissionDenied") {
                  Write-Warning "You do not have permission to install a module to '$InstallPath\$ModuleName'. You may need to be elevated. (Press Ctrl+C to cancel)"
               } 
            }
         }
   
         if(!$InstallPath -or !(Test-Path $InstallPath)){
            $Answer = $Host.UI.PromptForChoice(
               "Please choose an install path.",
               "Choose a Module Folder (use ? to see the full paths)",
               ([System.Management.Automation.Host.ChoiceDescription[]]$ChoicesWithHelp),
               $Default)
      
            if($Answer -ge $index) {
               $InstallPath = Read-Host ("You should pick a path that's already in your PSModulePath. " + 
                                          "To choose again, press Enter.`n" +
                                          "Otherwise, type the path for a 'Modules' folder you want to create")
            } else {
               $InstallPath = $ChoicesWithHelp[$Answer].HelpMessage
            }
         }
      }
   
      return $InstallPath
   }
}

function Test-ExecutionPolicy {
  #.Synopsis
  #   Validate the ExecutionPolicy
  param()

  $Policy = Get-ExecutionPolicy
  if(([Microsoft.PowerShell.ExecutionPolicy[]]"Restricted","Default") -contains $Policy) {
    $Warning = "Your execution policy is $Policy, so you will not be able import script modules."
  } elseif(([Microsoft.PowerShell.ExecutionPolicy[]]"AllSigned") -eq $Policy) {
    $Warning = "Your execution policy is $Policy, if modules are not signed, you won't be able to import them."
  }
  if($Warning) {
    Write-Warning ("$Warning`n" +
        "You may want to change your execution policy to RemoteSigned, Unrestricted or even Bypass.`n" +
        "`n" +
        "        PS> Set-ExecutionPolicy RemoteSigned`n" +
        "`n" +
        "For more information, read about execution policies by executing:`n" +
        "        `n" +
        "        PS> Get-Help about_execution_policies`n")
  } elseif(([Microsoft.PowerShell.ExecutionPolicy]"Unrestricted") -eq $Policy) {
    Write-Host "Your execution policy is $Policy and should be fine. Note that modules flagged as internet may still cause warnings."
  } elseif(([Microsoft.PowerShell.ExecutionPolicy]"RemoteSigned") -contains $Policy) {
    Write-Host "Your execution policy is $Policy and should be fine. Note that modules flagged as internet will not load if they're not signed."
  } 
}

# FULL # BEGIN FULL: These cmdlets are only necessary in the full version of the module
function Get-ConfigData {
  #.Synopsis
  #   Gets the modulename.ini settings as a hashtable
  #.Description
  #   Parses the non-comment lines in the config file as a simple hashtable, 
  #   parsing it as string data, and replacing {SpecialFolder} paths
  [CmdletBinding(DefaultParameterSetname="FromFile")]
  param()
  end {
    $Results = Import-LocalStorage $PSScriptRoot UserSettings.psd1

    # Our ConfigData has InstallPaths which may use tokens:
    foreach($Key in $($Results.InstallPaths.Keys)) {
      $Results.InstallPaths.$Key = $(
        foreach($StringData in @($Results.InstallPaths.$Key)) {
          $Paths = [Regex]::Matches($StringData, "{(?:$($Script:SpecialFolderNames -Join "|"))}")
          for($i = $Paths.Count - 1; $i -ge 0; $i--) {
            if($Path = Get-SpecialFolder $Paths[$i].Value.Trim("{}") -Value) {
              $StringData = $StringData.Remove($Paths[$i].Index,$Paths[$i].Length).Insert($Paths[$i].Index, $Path)
              break
            }
          }
          $StringData
        }
      )
    }

    # Our ConfigData has Repositories which may use tokens in their roots
    # The Repositories has to be an array:
    $Results.Repositories = @(
      foreach($Repo in $Results.Repositories) {
        foreach($Key in @($Repo.Keys)) {
          $Repo.$Key = $(
            foreach($StringData in @($Repo.$Key)) {
              $Paths = [Regex]::Matches($StringData, "{(?:$($Script:SpecialFolderNames -Join "|"))}")
              for($i = $Paths.Count - 1; $i -ge 0; $i--) {
                if($Path = Get-SpecialFolder $Paths[$i].Value.Trim("{}") -Value) {
                  $StringData = $StringData.Remove($Paths[$i].Index,$Paths[$i].Length).Insert($Paths[$i].Index, $Path)
                  break
                }
              }
              $StringData
            }
          )
        }
        $Repo
      }
    )
    return $Results
  }
}

function Set-ConfigData {
  #.Synopsis
  #   Updates the config file with the specified hashtable
  [CmdletBinding()]
  param(
    # The config hashtable to save
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [Hashtable]$ConfigData
  )
  end {
    # When serializing the ConfigData we want to tokenize the path
    # So that it will be user-agnostic
    $table = Get-SpecialFolder
    $table = $table.GetEnumerator() | Sort-Object Value -Descending

    # Our ConfigData has InstallPaths and Repositories
    # We'll explicitly save just those:
    $SaveData = @{ InstallPaths = @{}; Repositories = @{} }

    # Our ConfigData has InstallPaths which may use tokens:
    foreach($Key in $($ConfigData.InstallPaths.Keys)) {
      $SaveData.InstallPaths.$Key = $ConfigData.InstallPaths.$Key
      foreach($kvPath in $table) {
        if($ConfigData.InstallPaths.$Key -like ($kvPath.Value +"*")) {
          $SaveData.InstallPaths.$Key = $ConfigData.InstallPaths.$Key -replace ([regex]::Escape($kvPath.Value)), "{$($kvPath.Key)}"
          break
        }
      }
    }

    # Our ConfigData has Repositories which may use tokens in their roots
    # The Repositories has to be an array:
    $SaveData.Repositories = @(
      foreach($Repo in $ConfigData.Repositories) {
        foreach($Key in @($Repo.Keys)) {
          foreach($kvPath in $table) {
            if($Repo.$Key -like ($kvPath.Value +"*")) {
              $Repo.$Key = $Repo.$Key -replace ([regex]::Escape($kvPath.Value)), "{$($kvPath.Key)}"
              break
            }
          }
        }
        $Repo
      }
    )


    $ConfigString = "# You can edit this file using the ConfigData commands: Get-ConfigData and Set-ConfigData`n" +
                    "# For a list of valid {SpecialFolder} tokens, run Get-SpecialFolder`n" +
                    "# Note that the default InstallPaths here are the ones recommended by Microsoft:`n" +
                    "# http://msdn.microsoft.com/en-us/library/windows/desktop/dd878350`n" +
                    "#`n" +
                    "# Repositories: must be an array of hashtables with Type and Root`n" +
                    "#   Optionally, Repositories may have a name (useful for filtering Find-Module)`n" +
                    "#   and may include settings/parameters for the Repository's FindModule command`n"

    Export-LocalStorage -Module $PSScriptRoot -Name UserSettings.psd1 -InputObject $ConfigData -CommentHeader $ConfigString
  }
}

function Test-ConfigData {
  #.Synopsis
  #  Validate and configure the module installation paths
  [CmdletBinding()]
  param(
    # A Name=Path hashtable containing the paths you want to use in your configuration
    $ConfigData = $(Get-ConfigData)
  )

  foreach($path in @($ConfigData.InstallPaths.Keys)) {
    $name = $path -replace 'Path$'
    $folder = $ConfigData.$path
    do {
      ## Create the folder, if necessary
      if(!(Test-Path $folder)) {
        Write-Warning "The $name module location does not exist. Please validate:"
        $folder = Read-Host "Press ENTER to accept the current value:`n`t$($ConfigData.$path)`nor type a new path"
        if([string]::IsNullOrWhiteSpace($folder)) { $folder = $ConfigData.$path }

        if(!(Test-Path $folder)) {
          $CP, $ConfirmPreference = $ConfirmPreference, 'Low'
          if($PSCmdlet.ShouldContinue("The folder '$folder' does not exist, do you want to create it?", "Configuring <$name> module location:")) {
            $ConfirmPreference = $CP
            if(!(New-Item $folder -Type Directory -Force -ErrorAction SilentlyContinue -ErrorVariable fail))
            {
              Write-Warning ($fail.Exception.Message + "`nThe $name Location path '$folder' couldn't be created.`n`nYou may need to be elevated.`n`nPlease enter a new path, or press Ctrl+C to give up.")
            }
          }
          $ConfirmPreference = $CP
        }
      }

      ## Note: PSModulePath entries don't necessarily exist
      [string[]]$PSModulePaths = $Env:PSModulePath -split ";" #| Convert-Path -ErrorAction 0

      ## Add it to the PSModulePath, if necessary
      if((Test-Path $folder) -and ($PSModulePaths -notcontains (Convert-Path $folder))) {
        $folder = Convert-Path $folder
        $CP, $ConfirmPreference = $ConfirmPreference, 'Low'
        if($PSCmdlet.ShouldContinue("The folder '$folder' is not in your PSModulePath, do you want to add it?", "Configuring <$name> module location:")) {
          $ConfirmPreference = $CP          
          # Global and System paths need to go in the Machine registry to work properly
          if("Global","System","Common" -contains $name) {
            try {
              $PsMP = [System.Environment]::GetEnvironmentVariable("PSModulePath", "Machine") + ";" + $Folder
              $PsMP = ($PsMP -split ";" | Where-Object { $_ } | Select-Object -Unique) -Join ";"
              [System.Environment]::SetEnvironmentVariable("PSModulePath",$PsMP,"Machine")
              $Env:PSModulePath = ($PSModulePaths + $folder) -join ";"
            }
            catch [System.Security.SecurityException] 
            {
              Write-Warning ($_.Exception.Message + " The $name path '$folder' couldn't be added to your Local Machine PSModulePath.")
              if($PSCmdlet.ShouldContinue("Do you want to store the path '$folder' in your <User> PSModulePath instead?", "Configuring <$name> module location:")) {
                try {
                  $PsMP = [System.Environment]::GetEnvironmentVariable("PSModulePath", "User") + ";" + $Folder
                  $PsMP = ($PsMP -split ";" | Where-Object { $_ } | Select-Object -Unique) -Join ";"
                  [System.Environment]::SetEnvironmentVariable("PSModulePath", $PsMP, "User")
                  $Env:PSModulePath = ($PSModulePaths + $folder) -join ";"
                  Write-Host "Added '$folder' to your User PSModulePath instead."
                }
                catch [System.Security.SecurityException] 
                {
                  Write-Warning ($_.Exception.Message + " The $name path '$folder' couldn't be permanently added to your User PSModulePath. Adding for this session anyway.")
                  $Env:PSModulePath = ($PSModulePaths + $folder) -join ";"
                }
              }
            }
          } else {
            try {
              $PsMP = [System.Environment]::GetEnvironmentVariable("PSModulePath", "User") + ";" + $Folder
              $PsMP = ($PsMP -split ";" | Where-Object { $_ } | Select-Object -Unique) -Join ";"
              [System.Environment]::SetEnvironmentVariable("PSModulePath", $PsMP, "User")
              $Env:PSModulePath = ($PSModulePaths + $folder) -join ";"
            }
            catch [System.Security.SecurityException] 
            {
              Write-Warning ($_.Exception.Message + " The $name path '$folder' couldn't be permanently added to your User PSModulePath. Adding for this session anyway.")
              $Env:PSModulePath = ($PSModulePaths + $folder) -join ";"
            }
          }
        }
        $ConfirmPreference = $CP
      }
    } while(!(Test-Path $folder))
    $ConfigData.$path = $folder
  }
  # If you pass in a Hashtable, you get a Hashtable back
  if($PSBoundParameters.ContainsKey("ConfigData")) {
    Write-Output $ConfigData
    # Otherwise, we set it back where we got it from!
  } else {
    Set-ConfigData -ConfigData $ConfigData
  }
}

# These are special functions just for saving in the AppData folder...
function Get-LocalStoragePath {
   #.Synopsis
   #   Gets the LocalApplicationData path for the specified company\module 
   #.Description
   #   Appends Company\Module to the LocalApplicationData, and ensures that the folder exists.
   param(
      # The name of the module you want to access storage for (defaults to SplunkStanzaName)
      [Parameter(Position=0)]
      [ValidateScript({ 
         $invalid = $_.IndexOfAny([IO.Path]::GetInvalidFileNameChars())       
         if($invalid -eq -1){ 
            return $true
         } else {
            throw "Invalid character in Module Name '$_' at $invalid"
         }
      })]         
      [string]$Module = $SplunkStanzaName,

      # The name of a "company" to use in the storage path (defaults to "PowerShell Package Manager")
      [Parameter(Position=1)]
      [ValidateScript({ 
         $invalid = $_.IndexOfAny([IO.Path]::GetInvalidFileNameChars())       
         if($invalid -eq -1){ 
            return $true
         } else {
            throw "Invalid character in Company Name '$_' at $invalid"
         }
      })]         
      [string]$Company = "PowerShell Package Manager"      

   )
   end {
      if(!($path = $SplunkCheckpointPath)) {
         $path = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) $Company
      } 
      $path  = Join-Path $path $Module

      if(!(Test-Path $path -PathType Container)) {
         $null = New-Item $path -Type Directory -Force
      }
      Write-Output $path
   }
}

function Export-LocalStorage {
   #.Synopsis
   #   Saves the object to local storage with the specified name
   #.Description
   #   Persists objects to disk using Get-LocalStoragePath and Export-Metadata
   param(
      # A unique valid module name to use when persisting the object to disk
      [Parameter(Mandatory=$true, Position=0)]
      [ValidateScript({ 
         $invalid = $_.IndexOfAny([IO.Path]::GetInvalidPathChars())       
         if($invalid -eq -1){ 
            return $true
         } else {
            throw "Invalid character in Module Name '$_' at $invalid"
         }
      })]      
      [string]$Module,

      # A unique object name to use when persisting the object to disk
      [Parameter(Mandatory=$true, Position=1)]
      [ValidateScript({ 
         $invalid = $_.IndexOfAny([IO.Path]::GetInvalidFileNameChars())       
         if($invalid -eq -1){ 
            return $true
         } else {
            throw "Invalid character in Object Name '$_' at $invalid"
         }
      })]      
      [string]$Name,

      # The scope to store the data in. Defaults to storing in the ModulePath
      [ValidateSet("Module", "User")]
      $Scope,

      # comments to place on the top of the file (to explain it's settings)
      [string[]]$CommentHeader,

      # The object to persist to disk
      [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=10)]
      $InputObject
   )
   begin {
      $invalid = $Module.IndexOfAny([IO.Path]::GetInvalidFileNameChars())       

      if(($Scope -ne "User") -and $invalid -and (Test-Path $Module))
      {
         $ModulePath = Resolve-Path $Module
      } 
      elseif($Scope -eq "Module") 
      {
         $Module = Split-Path $Module -Leaf
         $ModulePath = Read-Module $Module -ListAvailable | Select -Expand ModuleBase -First 1
      }

      # Scope -eq "User"
      if(!$ModulePath -or !(Test-Path $ModulePath)) {
         $Module = Split-Path $Module -Leaf
         $ModulePath = Get-LocalStoragePath $Module
         if(!(Test-Path $ModulePath) -and ($Scope -ne "Module")) {
            $Null = New-Item -ItemType Directory $ModulePath
         }
      }

      if(!(Test-Path $ModulePath)) {
         Write-Error "The folder for storage doesn't exist: $ModulePath"
      }

      $ModulePath = Resolve-Path $ModulePath -ErrorAction Stop

      # Make sure it has a PSD1 extension
      if($Name -notmatch '.*\.psd1$') {
        $Name = "${Name}.psd1"
      }

      $Path = Join-Path $ModulePath $Name

      if($PSBoundParameters.ContainsKey("InputObject")) {
         Write-Verbose "Clean Export"
         Write-Verbose ""
         Export-Metadata -Path $Path -InputObject $InputObject -CommentHeader $CommentHeader
         $Output = $null
      } else {
         $Output = @()
      }
   }
   process {
    if($Output) {
      $Output += $InputObject
    }
   }
   end {
      if($Output) {
         Write-Verbose "Tail Export"
         # Avoid arrays when they're not needed:
         if($Output.Count -eq 1) { $Output = $Output[0] }
         Export-Metadata -Path $Path -InputObject $Output -CommentHeader $CommentHeader
      }
   }
}

function Import-LocalStorage {
   #.Synopsis
   #   Loads an object with the specified name from local storage 
   #.Description
   #   Retrieves objects from disk using Get-LocalStoragePath and Import-CliXml
   param(
      # A unique valid module name to use when persisting the object to disk
      [Parameter(Mandatory=$true, Position=0)]
      [string]$Module,

      # A unique object name to use when persisting the object to disk
      [Parameter(Position=1)]
      [ValidateScript({ 
         $invalid = $_.IndexOfAny([IO.Path]::GetInvalidPathChars())       
         if($invalid -eq -1){ 
            return $true
         } else {
            throw "Invalid character in Object Name '$_' at $invalid"
         }
      })]      
      [string]$Name = '*',

      # The scope to store the data in. Defaults to storing in the ModulePath
      [ValidateSet("Module", "User")]
      $Scope,

      # A default value (used in case there's an error importing):
      [Parameter()]
      [Object]$DefaultValue
   )
   end {
      $invalid = $Module.IndexOfAny([IO.Path]::GetInvalidFileNameChars())       
      if(($Scope -ne "User") -and $invalid -and (Test-Path $Module)) 
      {
         $ModulePath = Resolve-Path $Module
      } 
      elseif($Scope -eq "Module") 
      {
         $Module = Split-Path $Module -Leaf
         $ModulePath = Read-Module $Module -ListAvailable | Select -Expand ModuleBase -First 1
      }

      # Scope -eq "User"
      if(!$ModulePath -or !(Test-Path $ModulePath)) {
         $Module = Split-Path $Module -Leaf
         $ModulePath = Get-LocalStoragePath $Module
         if(!(Test-Path $ModulePath) -and ($Scope -ne "Module")) {
            $Null = New-Item -ItemType Directory $ModulePath
         }
      }

      if(!(Test-Path $ModulePath)) {
         Write-Error "The folder for storage doesn't exist: $ModulePath"
      }

      # Make sure it has a PSD1 extension
      if($Name -notmatch '.*\.psd1$') {
        $Name = "${Name}.psd1"
      }

      $Path = Join-Path $ModulePath $Name

      try {
         $Path = Resolve-Path $Path -ErrorAction Stop
         if(@($Path).Count -gt 1) {
            $Output = @{}
            foreach($Name in $Path) {
               $Key = Split-Path $Name -Leaf
               $Output.$Key = Import-Metadatae -Path $Name
            }
         } else {
            Import-Metadata -Path $Path
         }
      } catch {
         if($PSBoundParameters.ContainsKey("DefaultValue")) {
            Write-Output $DefaultValue
         } else {
            throw
         }
      }
   }
}
                              
Export-ModuleMember -Function Import-LocalStorage, Export-LocalStorage, Get-LocalStoragePath,
                              Get-SpecialFolder, Select-ModulePath, Test-ExecutionPolicy, 
                              Get-ConfigData, Set-ConfigData, Test-ConfigData
# FULL # END FULL

# SIG # Begin signature block
# MIIarwYJKoZIhvcNAQcCoIIaoDCCGpwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsvptVHHAuSP4Ja2UQrwIRGxE
# 4uOgghXlMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggahMIIFiaADAgECAhADS1DyPKUAAEvdY0qN2NEFMA0GCSqGSIb3DQEBBQUAMG8x
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29k
# ZSBTaWduaW5nIENBLTEwHhcNMTMwMzE5MDAwMDAwWhcNMTQwNDAxMTIwMDAwWjBt
# MQswCQYDVQQGEwJVUzERMA8GA1UECBMITmV3IFlvcmsxFzAVBgNVBAcTDldlc3Qg
# SGVucmlldHRhMRgwFgYDVQQKEw9Kb2VsIEguIEJlbm5ldHQxGDAWBgNVBAMTD0pv
# ZWwgSC4gQmVubmV0dDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMPj
# sSDplpNPrcGhb5o977Z7VdTm/BdBokBbRRD5hGF+E7bnIOEK2FTB9Wypgp+9udd7
# 6nMgvZpj4gtO6Yj+noUcK9SPDMWgVOvvOe5JKKJArRvR5pDuHKFa+W2zijEWUjo5
# DcqU2PGDralKrBZVfOonity/ZHMUpieezhqy98wcK1PqDs0Cm4IeRDcbNwF5vU1T
# OAwzFoETFzPGX8n37INVIsV5cFJ1uGFncvRbAHVbwaoR1et0o01Jsb5vYUmAhb+n
# qL/IA/wOhU8+LGLhlI2QL5USxnLwxt64Q9ZgO5vu2C2TxWEwnuLz24SAhHl+OYom
# tQ8qQDJQcfh5cGOHlCsCAwEAAaOCAzkwggM1MB8GA1UdIwQYMBaAFHtozimqwBe+
# SXrh5T/Wp/dFjzUyMB0GA1UdDgQWBBRfhbxO+IGnJ/yiJPFIKOAXo+DUWTAOBgNV
# HQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwcwYDVR0fBGwwajAzoDGg
# L4YtaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL2Fzc3VyZWQtY3MtMjAxMWEuY3Js
# MDOgMaAvhi1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vYXNzdXJlZC1jcy0yMDEx
# YS5jcmwwggHEBgNVHSAEggG7MIIBtzCCAbMGCWCGSAGG/WwDATCCAaQwOgYIKwYB
# BQUHAgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9y
# eS5odG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYA
# IAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkA
# dAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAA
# RABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAA
# UgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAA
# dwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4A
# ZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkA
# bgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wgYIGCCsGAQUFBwEBBHYwdDAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEwGCCsGAQUFBzAC
# hkBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURD
# b2RlU2lnbmluZ0NBLTEuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEFBQAD
# ggEBABv8O1PicJ3pbsLtls/jzFKZIG16h2j0eXdsJrGZzx6pBVnXnqvL4ZrF6dgv
# puQWr+lg6wL+Nxi9kJMeNkMBpmaXQtZWuj6lVx23o4k3MQL5/Kn3bcJGpdXNSEHS
# xRkGFyBopLhH2We/0ic30+oja5hCh6Xko9iJBOZodIqe9nITxBjPrKXGUcV4idWj
# +ZJtkOXHZ4ucQ99f7aaM3so30IdbIq/1+jVSkFuCp32fisUOIHiHbl3nR8j20YOw
# ulNn8czlDjdw1Zp/U1kNF2mtZ9xMYI8yOIc2xvrOQQKLYecricrgSMomX54pG6uS
# x5/fRyurC3unlwTqbYqAMQMlhP8wggajMIIFi6ADAgECAhAPqEkGFdcAoL4hdv3F
# 7G29MA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0Rp
# Z2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMTAyMTExMjAwMDBaFw0yNjAy
# MTAxMjAwMDBaMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTEwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQCcfPmgjwrKiUtTmjzsGSJ/DMv3SETQPyJumk/6zt/G0ySR/6hS
# k+dy+PFGhpTFqxf0eH/Ler6QJhx8Uy/lg+e7agUozKAXEUsYIPO3vfLcy7iGQEUf
# T/k5mNM7629ppFwBLrFm6aa43Abero1i/kQngqkDw/7mJguTSXHlOG1O/oBcZ3e1
# 1W9mZJRru4hJaNjR9H4hwebFHsnglrgJlflLnq7MMb1qWkKnxAVHfWAr2aFdvftW
# k+8b/HL53z4y/d0qLDJG2l5jvNC4y0wQNfxQX6xDRHz+hERQtIwqPXQM9HqLckvg
# VrUTtmPpP05JI+cGFvAlqwH4KEHmx9RkO12rAgMBAAGjggNDMIIDPzAOBgNVHQ8B
# Af8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwggHDBgNVHSAEggG6MIIBtjCC
# AbIGCGCGSAGG/WwDMIIBpDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5kaWdpY2Vy
# dC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwICMIIBVh6C
# AVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBp
# AGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABh
# AG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBD
# AFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5
# ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABs
# AGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABv
# AHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBj
# AGUALjASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQW
# BBR7aM4pqsAXvkl64eU/1qf3RY81MjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYun
# pyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAe3IdZP+IyDrBt+nnqcSHu9uUkteQ
# WTP6K4feqFuAJT8Tj5uDG3xDxOaM3zk+wxXssNo7ISV7JMFyXbhHkYETRvqcP2pR
# ON60Jcvwq9/FKAFUeRBGJNE4DyahYZBNur0o5j/xxKqb9to1U0/J8j3TbNwj7aqg
# TWcJ8zqAPTz7NkyQ53ak3fI6v1Y1L6JMZejg1NrRx8iRai0jTzc7GZQY1NWcEDzV
# sRwZ/4/Ia5ue+K6cmZZ40c2cURVbQiZyWo0KSiOSQOiG3iLCkzrUm2im3yl/Brk8
# Dr2fxIacgkdCcTKGCZlyCXlLnXFp9UH/fzl3ZPGEjb6LHrJ9aKOlkLEM/zGCBDQw
# ggQwAgEBMIGDMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTECEANLUPI8pQAAS91jSo3Y0QUwCQYF
# Kw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJ
# KoZIhvcNAQkEMRYEFOiTM7rq9ymAiYsxdYxGuv0MH+V9MA0GCSqGSIb3DQEBAQUA
# BIIBAEy2atg6jdHnUvZKevsQgpFI7YTGC8ZX3uZHK+Uum+iEZPGyM3yPQnccE0UO
# uD0e3zknFyezuUtkGmnnCYBM3Sr93Yzax+WIyQ70pPF75gG91LzDopCONkDXvASs
# mo7LMyc0BUXHdPRKCuMLYDHZ3wdK3j9VeNrQhvYRca+1oD9nVNfhoJfay9bgoUfX
# t/IPvHWy/Dmr8kZ2qDtbBY1fReSeaOoUngf6ZqkFotAgK/caK24yZ8fyEtkxBno8
# EBmBilOg8zlIl9852ShRZp2p8f54EtNfx6UegGTFiVTaLTdqOllkP08KvuUcbDip
# U8pcxepYWixKPHMg2UImg92KtE+hggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQC
# AQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0Eg
# LSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMxMTA0MDcxOTM4WjAjBgkq
# hkiG9w0BCQQxFgQUarw0jm0jQpB8sa7jxqjOgegtk7kwDQYJKoZIhvcNAQEBBQAE
# ggEAc5p9IL34RG651joAkekPoSA5Wbm9GPPHVSehZkxot0IY5r2C9x8vTTjwjQjI
# K074TQ31QyJmu5dxQMTUmCmBUdfuR8KIODJVSUeVdqyBLuFaHVmZZF5Sr5kfLFxw
# YqzK2JSGpYSZOuk7BmD5RmmXz2ssPmv4O+46MIogCSi0YOSup+AE54kS12GLCOzU
# ApYZpY14Ig+7855+3TyELWpvJD4f4h/PhAhkydyT7WXvdGUDr5GBkvDUfV5/ujGf
# nFjg852S8yMdXKvcqNQaOUguQLkMtDIXXcUOf/1DN6KjdTz7uYuD+pzFHkNb5dxA
# RPTPi2Fs+9ktpLabcX9LVD/cRQ==
# SIG # End signature block
