function Get-ShortenedPath {
<#
	.SYNOPSIS 
	Gets a shortened version of the current path
	.DESCRIPTION
	Gets a shortened version of the current path by replacing all but the current folder with a single character
	so that deep folder structures do not ruin the prompt.
	Adapted from: http://winterdom.com/2008/08/mypowershellprompt
#>
    param([string] $path)
	$loc = $path.Replace($HOME, '~')
	# remove prefix for UNC paths
	$loc = $loc -replace '^[^:]+::', ''
	# make path shorter like tabs in Vim,
	# handle paths starting with \\ and . correctly
	return ($loc -replace '\\(\.?)([^\\])[^\\]*(?=\\)','\$1$2')
}
