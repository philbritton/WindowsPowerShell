function Get-TfsWorkspaceGetLocalVersion() {
<#
	.SYNOPSIS
	Gets the changeset # of the workspace and server, then compares them.
	Returns just the changeset number if both match, which means local and
	server are in sync.  Returns the local changeset number and the server
	changeset number prepended on it if the numbers don't match.
#>
	$changesets = Get-TfsVersions
    
    # Gets current workspace "version"
	$local = $changesets[0]
	
	# Gets current server "version"
	$server = $changesets[1]

	if ($local -eq $server -or $server -eq $null) {
		return $local;
	}
	
	return "$local *$server" 
}
