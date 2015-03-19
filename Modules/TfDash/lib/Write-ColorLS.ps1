<#
	Description: Get-ChildItem override to provide color
    Adapted from: http://stackoverflow.com/questions/9406434/powershell-properly-coloring-get-childitem-output-once-and-for-all
#>

function Global:Write-ColorLS {
	param ([string]$color = "white", $file)
	Write-host ("{0,-7} {1,25} {2,10} {3}" -f $file.mode, ([String]::Format("{0,10}  {1,8}", $file.LastWriteTime.ToString("d"), $file.LastWriteTime.ToString("t"))), $file.length, $file.name) -foregroundcolor $color 
}

function Global:Test-ReparsePoint([string]$path) {
  $file = Get-Item $path -Force -ea 0
  return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

New-CommandWrapper Out-Default -Process {
    $regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $compressed = New-Object System.Text.RegularExpressions.Regex('\.(zip|tar|gz|rar|jar|war|7z)$', $regex_opts)
    $executable = New-Object System.Text.RegularExpressions.Regex('\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$', $regex_opts)
    $text_files = New-Object System.Text.RegularExpressions.Regex('\.(txt|cfg|conf|ini|csv|log|xml|java|c|cpp|cs|vb|config|aspx|ascx|resx|master|htm|html|ashx|xsl|xslt|asax|js|css|cfm|sitemap)$', $regex_opts)
	$vsProjects = New-Object System.Text.RegularExpressions.Regex('\.(csproj|vbproj|sln)$', $regex_opts)
	$vsIgnores = New-Object System.Text.RegularExpressions.Regex('\.(user|suo|vssscc|vspscc)$', $regex_opts)

    if(($_ -is [System.IO.DirectoryInfo]) -or ($_ -is [System.IO.FileInfo])) {
        if(-not ($notfirst)) {
           Write-Host
           Write-Host "    Directory: " -noNewLine
           Write-Host " $(pwd)`n" -foregroundcolor "Magenta"           
           Write-Host "Mode                LastWriteTime     Length Name"
           Write-Host "----                -------------     ------ ----"
           $notfirst=$true
        }

        if (Test-ReparsePoint($_.FullName)) {
			Write-ColorLS "Cyan" $_
		}
		elseif ($_ -is [System.IO.DirectoryInfo]) {
            Write-ColorLS "Magenta" $_                
        }
        elseif ($compressed.IsMatch($_.Name)) {
            Write-ColorLS "DarkGreen" $_
        }
        elseif ($executable.IsMatch($_.Name)) {
            Write-ColorLS "Red" $_
        }
        elseif ($text_files.IsMatch($_.Name)) {
            Write-ColorLS "Yellow" $_
        }
		elseif ($vsProjects.IsMatch($_.Name)) {
			Write-ColorLS "Green" $_
		}
		elseif ($vsIgnores.IsMatch($_.Name)) {
			Write-ColorLS "DarkGray" $_
		}
        else {
            Write-ColorLS "White" $_
        }

		$_ = $null
    }
} -end {
    write-host ""
}

function Get-LSPadded
{
    param ($dir)
    Get-ChildItem $dir
    Write-Host
    Get-DirectorySize $dir
}

function Get-DirectorySize
{
    param ($dir)
    $bytes = 0

    Get-Childitem $dir | foreach-object {

        if ($_ -is [System.IO.FileInfo])
        {
            $bytes += $_.Length
        }
    }

    if ($bytes -ge 1KB -and $bytes -lt 1MB)
    {
        Write-Host ("Total Size: " + [Math]::Round(($bytes / 1KB), 2) + " KB")   
    }

    elseif ($bytes -ge 1MB -and $bytes -lt 1GB)
    {
        Write-Host ("Total Size: " + [Math]::Round(($bytes / 1MB), 2) + " MB")
    }

    elseif ($bytes -ge 1GB)
    {
        Write-Host ("Total Size: " + [Math]::Round(($bytes / 1GB), 2) + " GB")
    }    

    else
    {
        Write-Host ("Total Size: " + $bytes + " bytes")
    }
}