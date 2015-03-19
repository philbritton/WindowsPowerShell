function Get-TfsWorkspaceMappingNeedsRefresh() {
<#
	.SYNOPSIS
	Attempts to determine whether or not the prompt needs to be updated if the
	current folder is a different branch or if it's been switched to another 
	branch.
#>
    $currentLocation = (pwd).Path;
    $needsRefresh = -not $currentLocation.Contains($global:previousLocation) -or $global:currentTfsBranch -eq $null;

    if ($currentLocation.Contains($global:previousLocation) -eq $False) {
      $global:previousLocation = $currentLocation;
    }

    return $needsRefresh;
}
