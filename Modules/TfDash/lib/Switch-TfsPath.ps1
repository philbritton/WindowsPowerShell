function Switch-TfsPath([string]$path) {
<#
	.SYNOPSIS
	Switches your TFS workfolder mapping to the provided TFS path.
	.DESCRIPTION
	The Switch-TfsPath function uses TFS's command-line "tf workfold" command to re-map your local workfolder to the specified TFS path from the current directory.
	If the current directory is not the root of the workspace, it will map a *new* folder instead of re-mapping the existing folder.  Use caution.
	.PARAMETER path
	The TFS path being mapped to.
	.EXAMPLE
	Switch-TfsPath "$/Web/Source/UAT"
#>
	if ($path -eq "") {
		Get-Help Switch-TfsPath -detailed
		return
	}

	tf workfold /map $path .\ | foreach-object {
		$item = "> " + $_
		Write-Progress -id 2 -parentId 1 -Activity "Switching workfolder to $path.  Don't forget to do a 'Get-TfsLatest'" -Status $item
	}
	
	Reset-TfsGlobals
}
