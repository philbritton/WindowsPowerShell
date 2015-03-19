$tfpt_reg_key = 'HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\Microsoft.TeamFoundation.PowerShell'
$tfpt_reg_key_psv3 = 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellSnapIns\Microsoft.TeamFoundation.PowerShell'
$isWin7AndUp = [Environment]::OSVersion.Version -ge (New-Object 'Version' 6,1)

# Add necessary registry entry to be able to use the TFPT cmdlets from x64
function Register-TfptCmdlets64([string]$version = "2013") {
  if ($isWin7AndUp) {
    if (-not (Test-Path $tfpt_reg_key)) {
      regedit /s $PSScriptRoot\tfpt$version-x64.reg
    }
  }
}

# Add necessary registry entry to be able to use the TFPT cmdlets from x64 and PowerShell v3
#function Register-TfptCmdlets64ForPoshV3 {
#  if ($isWin7AndUp) {
#    if (-not (Test-Path $tfpt_reg_key_psv3)) {
#      regedit /s $PSScriptRoot\tfpt-x64-psv3.reg
#    }
#  }
#}

# Make the TFPT PowerShell Cmdlets available
function Register-TfptCmdlets([string]$version = "2013") {
	$tfpt_assm = "${Env:ProgramFiles(x86)}\Microsoft Team Foundation Server $version Power Tools\Microsoft.TeamFoundation.PowerTools.PowerShell.dll"
	if (Test-Path $tfpt_assm) {
		Add-PSSnapin Microsoft.TeamFoundation.PowerShell
	} else {
		Write-Warning "Microsoft Team Foundation Server $version Power Tools PowerShell CmdLets failed to register.  Make sure the cmdlets are installed (from TFPT installer).  If they are, run your PowerShell command line again if this was your first time using them."
	}
}
