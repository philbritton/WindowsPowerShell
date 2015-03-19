function Get-TfsReview() {
<#
	.SYNOPSIS
	Recursively review (diff/view) workspace or shelveset changes.
	.DESCRIPTION
	Use this command when you would like to recursively review changes in your workspace or shelveset in any order you would like.  Files can be viewed or diffed as appropriate. If no options are specified, all pending changes in the workspace are displayed.
	.EXAMPLE
	Get-TfsReview
#>
	Write-Host " "
	Write-Host "Reviewing current pending changes recursively..." -f $cloc
	& $tfpt review . /recursive
	Write-Host " "
}
