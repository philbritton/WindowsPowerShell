function Get-TfsHistory([int]$count = 5) {
<#
	.SYNOPSIS
	Shows the last [n] changesets recursively from the current folder.  Default is 5.
	.DESCRIPTION
	Use this command when you'd like to see the last 5 changeset messages from any file or folder starting with the current folder.  Helpful for when you want to see and use some of the last commit messages.
	.PARAMETER count
	Number of changeset messages to stop after
	.EXAMPLE
	Get-TfsHistory
	.EXAMPLE
	Get-TfsHistory 20
#>
	Write-Host " "
	Write-Host "Showing history of the last $count changesets recursively..." -f $cloc
	$history = Get-TfsItemHistory . -recurse -stopafter:$count
	
    #foreach ($item in $history) {
	#	$item.Committer = $item.Committer -replace "[ActiveDirectoryDomainNameHere]\\", ""
	#}
	
	$history | select @{name="Version"; expression={$_.ChangesetId}}, @{name="Committer"; expression={$_.Committer.Substring($_.Committer.IndexOf("\")+1)}}, CodeReviewer, @{name="Date"; expression={$_.CreationDate}}, Comment | Format-Table -AutoSize
}
