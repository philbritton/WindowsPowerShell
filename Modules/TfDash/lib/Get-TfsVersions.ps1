function Get-TfsVersions() {
<#
	.SYNOPSIS
	Outputs the local and server changeset numbers.
#>
	$local = Get-TfsVersion "W"
	$server = Get-TfsVersion "T"
	
	Write-Output $local
	Write-Output $server
}

function Get-TfsVersion([string]$versionSpec) {
<#
	.SYNOPSIS
	Gets the largets changeset number of the current workspace based on the versionSpec provided.
	.PARAMETER versionSpec
    Date/Time         D"any .Net Framework-supported format"
                      or any of the date formats of the local machine
    Changeset number  Cnnnnnn
    Label             Llabelname
    Latest version    T
    Workspace         Wworkspacename;workspaceowner
	.EXAMPLE
	Get-TfsVersion T
	.EXAMPLE
	Get-TfsVersion W
	.EXAMPLE
	Get-TfsVersion D"2013-01-01"
	.EXAMPLE
	Get-TfsVersion C12345
#>
	try {
		$history = Get-TfsItemHistory -HistoryItem . -Recurse -StopAfter 1 -Version $versionSpec | %{ $_.ChangesetId }
	} catch {
		$history = $null
	}
	Write-Output $history
}
