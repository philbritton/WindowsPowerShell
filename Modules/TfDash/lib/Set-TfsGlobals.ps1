function Set-TfsGlobals {
<#
	.SYNOPSIS
	Sets some global TFS variables to avoid constantly calling tf.exe, tfpt.exe,
	and possibly TFPT PowerShell Cmdlets.
#>
	try {
		if ($(Get-TfsWorkspaceMappingNeedsRefresh)) {
		  $branchName = Get-TfsCurrentBranchName

		  if ($branchName -ne $null) {
			$global:localVersion = Get-TfsWorkspaceGetLocalVersion;
			$global:currentTfsBranch = $branchName;
			$global:previousLocation = (pwd).Path;
		  } else {
			Reset-TfsGlobals
		  }
		}
	} catch {
		Reset-TfsGlobals
	}
}

function Reset-TfsGlobals {
<#
	.SYNOPSIS
	Resets global TFS variables.
#>
	$global:localVersion = $null
	$global:previousLocation = $null
	$global:currentTfsBranch = $null
}
