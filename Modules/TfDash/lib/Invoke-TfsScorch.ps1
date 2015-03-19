function Invoke-TfsScorch([string]$params = "") {
<#
	.SYNOPSIS
	Recursively scorches the current workfolder from the current directory.
	.DESCRIPTION
	The Invoke-TfsScorch function uses the TFS Power Tools "tfpt scorch" command to 
	recursively delete untracked files and get the latest version based on a 
	diff of the local and server versions of files.
	
	This command is basically a clean-up to bring the local workspace to an 
	exact match of the remote path.
	.PARAMETER params
	Allows additional tfpt scorch switches to be specified.  Available 
	parameters:
	
	/noprompt              Do not show the list of items to be deleted and 
						   redownloaded in a dialog box for confirmation
	/exclude:filespec[,..] Files and directories matching a filespec in this 
						   list are excluded from processing
	/preview               Do not make changes; only list the potential actions
	/batchsize:num         Set the batch size for server calls (default 500)
	filespec...            Only files and directories matching these filespecs
						   are processed (inclusion list)
	.EXAMPLE
	Invoke-TfsScorch
	.EXAMPLE
	Invoke-TfsScorch /noprompt
#>
	if ($params.Contains("/noprompt")) {
		& $tfpt scorch . /recursive /deletes /diff $params | foreach-object {
			$item = "> " + $_
			Write-Progress -id 1 -Activity "Cleaning up your work folder from the current directory" -status $item
		}
	} else {
		& $tfpt scorch . /recursive /deletes /diff $params
	}
	
	Reset-TfsGlobals
}
