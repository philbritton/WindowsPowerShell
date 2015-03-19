function Undo-TfsChange([string]$path = ".", [switch]$WhatIf) {
<#
	.SYNOPSIS
	Undoes pending changes from the provided path recursively.
	.DESCRIPTION
	Uses the tf undo command to recursively undo pending changes from the provided path without prompting the user with a GUI interface.  Path defaults to current folder.  Provide -WhatIf switch to be prompted with a confirmation.
	.PARAMETER path
	Path to undo from.  Defaults to current folder.
	.PARAMETER -WhatIf
	Forces undo to prompt for a confirmation.
	.EXAMPLE
	Undo-TfsChange
	.EXAMPLE
	Undo-TfsChange .\HelloWorld\*.cs
	.EXAMPLE
	Undo-TfsChange -WhatIf
	.EXAMPLE
	Undo-TfsChange .\HelloWorld\*.cs -WhatIf
#>
	Write-Output " "
	Write-Output "Undoing pending changes recursively..."
	
	$cmd = "tf"
	$params = "undo", "/recursive", $path
	
	if (-not $WhatIf) {
		$params = $params + "/noprompt"
	}
	
	& $cmd $params
}
