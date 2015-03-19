function Get-TfsStatus([switch]$all) {
<#
	.SYNOPSIS
	Gets the TFS status of files from the current directory.
	.DESCRIPTION
	The Get-TfsStatus function uses the TFS "tf status" command-line command to check on the status of TFS-tracked files.
	Provide the -all switch and it will also provide a listing of untracked files.
	.PARAMETER all
	Switch to show status of all files, not just TFS-tracked files.
	.EXAMPLE
	Get-TfsStatus
	.EXAMPLE
	Get-TfsStatus -all
#>
	Write-Host " "
	Write-Host "Checking status of current folder recursively..." -f $cloc
	Get-TfsPendingChange . -recurse | 
		select Version, @{name="Date"; expression={"{0:d}" -f $_.CreationDate}}, @{name="Change"; expression={$_.ChangeType}}, @{name="Item"; expression={$_.ServerItem}} |
		Format-Table -AutoSize

	if ($all) {
		tf folderdiff . /recursive /view:targetOnly /noprompt
		Write-Host " "
	}
}
