function Write-ShortenedPath
{
	Write-Host (Get-ShortenedPath (pwd).Path) -NonewLine
}

function Write-TfsVcsStatus
{
  # TODO: Fix defect that causes tf.exe to be called regardless if we're in a workspace or not (SLOW)
	Set-TfsGlobals

	if ($global:currentTfsBranch -ne $null) {
		Write-Host " [" -n -f $cdelim
		Write-Host $global:currentTfsBranch -n -f $chost
		Write-Host " " -n
		Write-Host $global:localVersion -n -f DarkYellow
		Write-Host "]" -n -f $cdelim
	}
}
