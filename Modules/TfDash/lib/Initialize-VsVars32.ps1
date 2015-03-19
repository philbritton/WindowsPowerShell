function Initialize-VsVars32($version = "10.0")
{
        <#
                .SYNOPSIS
                Executes the Visual Studio batch file that sets up environment 
                variables specific to Visual Studio's command line.
                .PARAMETER version
                The version of Visual Studio to run the batch file for.  Default is "10.0".
                .EXAMPLE
                Initialize-VsVars32
                .EXAMPLE
                Initialize-VsVars32 "10.0"
        #>
        
    $key = "HKCU:SOFTWARE\Microsoft\VisualStudio\" + $version + "_Config"
    
    try {
        $VsKey = Get-ItemProperty $key
    } catch {
        Write-Error "There was an issue reading the regisry for the key: $key.  Please run Visual Studio $version first."
        return
    }
        
    $VsInstallPath = [System.IO.Path]::GetDirectoryName($VsKey.InstallDir)
    $VsToolsDir = [System.IO.Path]::GetDirectoryName($VsInstallPath)
    $VsToolsDir = [System.IO.Path]::Combine($VsToolsDir, "Tools")
    $BatchFile = [System.IO.Path]::Combine($VsToolsDir, "vsvars32.bat")
    Invoke-CmdScript $BatchFile
}
