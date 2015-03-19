TfDash wraps the TFS command-line tool and the Team Foundation Power Tools. It makes switching branches as simple as it is in Subversion, Git, and Mercurial (without requiring full branch downloads)!

# Installation

Clone this repository into your user Modules directory

```powershell
PS> cd (split-path $profile)
PS> cd .\Modules
PS> hg clone https://bitbucket.org/Sumo/tfdash
```

Open your PowerShell profile for editing

```powershell
PS> notepad $profile
```

And import this module somewhere near the top

```powershell
Import-Module tfdash
```

# Prerequisites

## Visual Studio Command Prompt
The [Visual Studio Command Prompt][2] "automatically sets the environment variables that enable you to easily use .NET Framework tools." We need `tf.exe` on your `PATH`. You _may_ use the [PowerShell Community Extensions][4], add this to your profile

```powershell
Import-VisualStudioVars
```

If you prefer simple, use the single-purpose [Posh-VsVars module][3] 


```powershell
Set-VsVars
```

Or, you can call a function that we provide 


```powershell
Initialize-VsVars32
```

## Team Foundation Server Power Tools
The [Power Tools][1] are "a set of enhancements, tools, and command-line utilities that increase productivity of Team Foundation Server scenarios." We currently support only TFPT 2010 and we'll look for the `tfpt.exe` in its installation directory.

It's nice to have the TFPT Cmdlets loaded, too, but we try to fall back on other commands when they're not available. Load them in your profile like this

```powershell
Add-PSSnapin Microsoft.TeamFoundation.PowerShell
```

Or, run our function, which checks that the snapin exists. We also have a workaround for 64-bit sessions, which are not officially supported yet (although, we suspect it doesn't work #20).

```powershell
Register-TfptCmdlets
```

# PowerShell Prompt

You can override the `prompt` function in your PowerShell profile to provide helpful TFS workspace information when the current directory is a mapped workspace folder. It's not as fancy as posh-git or posh-hg due to the client/server nature of TFS.  It only displays the name of the currently mapped branch (assuming workspaces are mapped to a single branch), the changeset # of the workspace, and optionally the changeset # of the server if different from the workspace version.

```powershell
function prompt {
  Write-Host $pwd -NoNewLine
  Write-TfsVcsStatus
  '> '
}
```

In the example below, you can see that we're on the `Main` branch (a TFS naming convention for the master branch). And the changeset number, 12345, is listed. When only one changeset is displayed, we are synchronized with the server.

```powershell
PS [Main 12345]>
``` 

In the example here, you can see that there are two changesets, indicating that the server is ahead of our local workspace.

```powershell
PS [Main 12345 *12350]>
```

As a bonus, you may replace the full working directory (`$pwd`) with a shortened path by using this function in your prompt, `Write-ShortenedPath`. A shortened prompt will look something like this, with each directory in the path before the current one being shortened to just it's first character.

```powershell
X:\a\b\c\SomeMappedFolder [Main 12345]>
```

# Usage

This is not an exhaustive list. Run this command to see all of the available functions and aliases.

```powershell
PS> gcm -module tfdash
```

## Get-TfsHistory
_aliases: `tf-history`, `tf-hist`, `tf-hi`, or `tf-log`_

Calls the `Get-TfsItemHistory` TFPT PowerShell cmdlet to get a table-formatted history of checkins. It is hard-coded to use "." (current folder) as the path, defaults to the newest 5 checkins, and does so recursively so that the history is more like what you'd get from `svn log` or `hg log`. Optionally, a section of this function can be commented out if there's a desire to remove an active directory domain name from the Committer field.  Just replace `[ActiveDirectoryDomainNameHere]` with the full name of the domain as it would appear in TFS checkins.  Take a look at `tf history` if you're unsure.

## Invoke-TfsSync
_aliases: `tf-sync`, `tf-switch`, `tf-sy`, or `tf-sw`_

Switches your TFS workfolder mapping to the provided TFS path and gets the latest version of the files.  The `Invoke-TfsSync` function calls `Invoke-TfsPull` and `Invoke-TfsUpdate` in order to provide branch switching functionality.

## Get-TfsStatus
_aliases: `tf-status`, or `tf-st`_

Gets the TFS status of files from the current directory.  The Get-TfsStatus function uses the TFS `tf status` command-line command to check on the status of TFS-tracked files.  Provide the `-all` switch and it will also provide a listing of untracked files by using `tf folderdiff`.

## Invoke-TfsUndoUnchanged
_aliases: `tf-uu`_

Undo unchanged files.  Uses the `tfpt uu` command to undo any unchanged files recursively when compared to the latest changes.

This is one of the most helpful commands as files tend to get accidentally or unknowingly checked out and TFS does not detect unchanged files during a checkin.  If you have junior developers who check out a whole solution, tracking down changes in history is almost impossible.  This command, when used properly, can help alleviate the problem and do so quickly so that it can become a part of a developer's normal process.


 [1]: http://www.microsoft.com/en-us/download/details.aspx?id=35775
 [2]: http://msdn.microsoft.com/en-us/library/ms229859.aspx
 [3]: https://github.com/Iristyle/Posh-VsVars
 [4]: http://pscx.codeplex.com/