function Undo-TfsUnchanged {
<#
	.SYNOPSIS
	Undo unchanged files
	.DESCRIPTION
	Uses the tfpt uu command to undo any unchanged files recursively when compared to the latest changes.
	.EXAMPLE
	Undo-TfsUnchanged
#>
	Write-Host " "
	Write-Host "Undoing unchanged files recursively..." -f $cloc
	& $tfpt uu /recursive .
	Write-Host " "
}

