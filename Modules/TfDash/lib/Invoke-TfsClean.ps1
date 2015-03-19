function Invoke-TfsClean([string]$params = "") {
<#
	.SYNOPSIS
	Recursively deletes files and folders not under version control.
	.DESCRIPTION
	The Invoke-TfsClean function uses the TFS Power Tools "tfpt treeclean" command to 
	recursively delete files and folders not under version control.
	
	This command is basically a clean-up to remove untracked files/folders.
	.PARAMETER params
	Allows additional tfpt treeclean switches to be specified.  Available 
	parameters:
	
	/noprompt              Operate in command-line mode only
	/exclude:filespec[,..] Files and directories matching a filespec in this 
						   list are excluded from processing
	/preview               Do not make changes; only list the potential actions
	/batchsize:num         Set the batch size for server calls (default 500)
	filespec...            Only files and directories matching these filespecs
						   are processed (inclusion list)
	.EXAMPLE
	Invoke-TfsClean
	.EXAMPLE
	Invoke-TfsClean /noprompt
#>
	if ($params.Contains("/noprompt")) {
		& $tfpt treeclean . /recursive $params | foreach-object {
			$item = "> " + $_
			Write-Progress -id 1 -Activity "Cleaning up your work folder from the current directory" -status $item
		}
	} else {
		& $tfpt treeclean . /recursive $params
	}
}
