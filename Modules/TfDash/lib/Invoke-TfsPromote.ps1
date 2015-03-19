function Invoke-TfsPromote(
    [switch]
    [alias("ni")]
    $noIgnore,
    [string]
    $exclude = ""
) {
<#
	.SYNOPSIS
	Recursively promotes changes in a local workspace to pended changes with TFS
	.DESCRIPTION
	The Invoke-TfsPromote function uses the TFS "tf reconcile /promote" command to recursively pend local changes, checking for adds, deletes, and differences from the current folder.
    .PARAMETER noIgnore
    Forces inclusions of files that would normally be ignored by default and/or by presence of .tfignore file.  Alias: ni.
    .PARAMETER exclude
    A comma-separated list of file/folder exclusions to skip.  Each one follows the standard TFS "itemspec" format.
	.EXAMPLE
	Invoke-TfsPromote
    .EXAMPLE
    Invoke-TfsPromote -ni
    .EXAMPLE
    Invoke-TfsPromote -ni -exclude "bin,obj"
#>
    Write-Host " "
    Write-host "Pending local changes in the current folder recursively, checking for adds, deletes, and differences" -f $cloc -NoNewline

    if ($noIgnore) {
		Write-Host "..."
        $ni = "/noignore"
    } else {
        Write-Host ", while skipping default ignored files and anything in .tfignore..." -f $cloc
    }

    if (-not [string]::IsNullOrWhiteSpace($exclude)) {
        $exclusion = "/exclude:$exclude"
    }

    tf reconcile . /promote /adds /deletes /diff /recursive $ni $exclusion
    
    Write-Host " "
}