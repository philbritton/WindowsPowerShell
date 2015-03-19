function Switch-TfsBranch([string]$path) {
<#
	.SYNOPSIS
	Switches your TFS workfolder mapping to the provided TFS path and gets the latest version of the files.
	.DESCRIPTION
	The Switch-TfsBranch function calls Switch-TfsPath and Get-TfsLatest in order to provide branch switching functionality.
	.PARAMETER path
	The TFS path being mapped to.
	.NOTES
	Command must be run from the root folder of the workspace.
	.EXAMPLE
	Switch-TfsBranch "$/Web/Source/UAT"
#>
  if ($path -eq "") {
    Get-Help Switch-TfsBranch -detailed
    return
  }

  $pattern = "\$.+:\s(.+)"
  $workspacePath = (tf workfold | Select-String -pattern $pattern).Matches[0].Groups[1].Value.Trim()
  $localPath = (pwd).Path.Trim()
  
  if ($workspacePath -ne $localPath) {
	Write-Host " "
	Write-Host "You must run this command from $workspacePath" -f $cerr
	return
  }
  
  Switch-TfsPath $path | foreach-object {
	Write-Progress -id 1 -Activity "Synchronizing workfolder to $path"
  }

  Get-TfsLatest
}
