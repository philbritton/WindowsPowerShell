function Get-TfsProperties([string]$path = ".") {
<#
	.SYNOPSIS
	Calls the "tf properties" command with the passed in path and returns the output.
	.PARAMETER path
	The local path to get TFS properties for.  Defaults to "."
    .EXAMPLE
	Get-TfsProperties
	.EXAMPLE
	Get-TfsProperties c:\some-path
#>
    return tf properties $path
}
