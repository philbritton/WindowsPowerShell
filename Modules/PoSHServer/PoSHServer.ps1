# Copyright (C) 2013 Yusuf Ozturk
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

function Start-PoSHServer {
 
<#
    .SYNOPSIS
     
        Powershell Web Server to serve HTML and Powershell web contents.
 
    .DESCRIPTION
     
        Listens a port to serve web content. Supports HTML and Powershell.
    
    .PARAMETER  WhatIf
     
        Display what would happen if you would run the function with given parameters.
    
    .PARAMETER  Confirm
     
        Prompts for confirmation for each operation. Allow user to specify Yes/No to all option to stop prompting.
    
    .EXAMPLE
     
        Start-PoSHServer -IP 127.0.0.1 -Port 8080
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net" -Port 8080
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -asJob
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -SSL -SSLPort 8443 -asJob
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -SSL -SSLIP "127.0.0.1" -SSLPort 8443 -asJob
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -DebugMode
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net,www.poshserver.net" -Port 8080
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net,www.poshserver.net" -Port 8080 -HomeDirectory "C:\inetpub\wwwroot"
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net,www.poshserver.net" -Port 8080 -HomeDirectory "C:\inetpub\wwwroot" -LogDirectory "C:\inetpub\wwwroot"
		
    .EXAMPLE
     
        Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -CustomConfig "C:\inetpub\config.ps1" -CustomJob "C:\inetpub\job.ps1"

    .INPUTS
    
        None
 
    .OUTPUTS
 
        None
	
    .NOTES
    
        Author: Yusuf Ozturk
        Website: http://www.yusufozturk.info
        Email: yusuf.ozturk@outlook.com
        Date created: 09-Oct-2011
        Last modified: 29-Jan-2013
        Version: 3.2
 
    .LINK
    
        http://www.poshserver.net
		
#>
 
[CmdletBinding(SupportsShouldProcess = $true)]
param (

    # Hostname
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'IP Address or Hostname')]
	[Alias('IP')]
    [string]$Hostname,
	
    # Port Number
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Port Number')]
    [string]$Port,
	
    # SSL IP Address
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL IP Address')]
    [string]$SSLIP,
	
    # SSL Port Number
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL Port Number')]
    [string]$SSLPort,
	
    # SSL Port Number
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'SSL Friendly Name. Example: poshserver.net')]
    [string]$SSLName,
	
    # Home Directory
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Home Directory. Example: C:\inetpub\wwwroot')]
    [string]$HomeDirectory,
	
    # Log Directory
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Log Directory. Example: C:\inetpub\wwwroot')]
    [string]$LogDirectory,

    # Custom Config Path    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Custom Config Path. Example: C:\inetpub\config.ps1')]
    [string]$CustomConfig,

    # Custom Child Config Path
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Custom Child Config Path. Example: C:\inetpub\childconfig.ps1')]
    [string]$CustomChildConfig,

    # Custom Job Path    
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Custom Job Path. Example: C:\inetpub\jobs.ps1')]
    [string]$CustomJob,
	
    # Background Job ID
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Background Job ID. Example: 52341')]
    [string]$JobID,
	
    # Enable SSL
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Enable SSL')]
    [switch]$SSL = $false,

    # Debug Mode
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Debug Mode')]
    [switch]$DebugMode = $false,
	
    # Background Job
    [Parameter(
        Mandatory = $false,
        HelpMessage = 'Run As Background Job')]
    [switch]$asJob = $false
)
	
	# Enable Debug Mode
	if ($DebugMode)
	{
		$DebugPreference = "Continue"
	}
	else
	{
		$ErrorActionPreference = "silentlycontinue"
	}
			
	# Get PoSH Server Module Path
	$ModulePaths = ($env:PSModulePath).Split(";")
	
	# Test Module Paths
	Foreach ($ModulePath in $ModulePaths)
	{
		$ModulePath = "$ModulePath\PoSHServer"
		$ModulePath = $ModulePath.Replace("\\","\")
		$ModulePathTest = Test-Path $ModulePath
		if ($ModulePathTest)
		{
			$PoSHModulePath = $ModulePath
		}
	}
	
	if (!$PoSHModulePath)
	{
		Write-Warning "Could not detect PoSH Server Module Path."
		Write-Warning "Aborting.."
		Break;
	}
	
	# Background Job ID
	if ($JobID)
	{
		$JobIDPath = "$PoSHModulePath\jobs\job-$JobID.txt"
		$TestJobID = Test-Path $JobIDPath
		if ($JobIDPath)
		{
			$JobIDContent = Get-Content $JobIDPath
			$Hostname = $JobIDContent.Split(";")[0]
			$Port = $JobIDContent.Split(";")[1]
			$SSLIP = $JobIDContent.Split(";")[2]
			$SSLPort = $JobIDContent.Split(";")[3]
			$SSLName = $JobIDContent.Split(";")[4]
			$HomeDirectory = $JobIDContent.Split(";")[5]
			$LogDirectory = $JobIDContent.Split(";")[6]
			$CustomConfig = $JobIDContent.Split(";")[7]
			$CustomChildConfig = $JobIDContent.Split(";")[8]
			$CustomJob = $JobIDContent.Split(";")[9]
		}
		else
		{
			Write-Warning "Job ID is not exist!"
			Write-Warning "Aborting.."
			Break;
		}
	}
	
	# Get Home and Log Directories
	if (!$HomeDirectory) { $HomeDirectory = "$PoSHModulePath\http" }
	if (!$LogDirectory) { $LogDirectory = "$PoSHModulePath\logs" }

	# Admin Privileges Verification
	. $PoSHModulePath\modules\adminverification.ps1
	
	# Server IP Verification
	. $PoSHModulePath\modules\ipverification.ps1
	
	# PHP Encoding Module
	. $PoSHModulePath\modules\phpencoding.ps1
	
	# Break Script If Something's Wrong
	if ($ShouldProcess -eq $false)
	{
		Break;
	}
	
	# Enable Background Job
	if ($asJob)
	{	
		if (!$Hostname)
		{
			$Hostname = "+"
			$TaskHostname = "localhost"
		}
		else
		{
			$TaskHostname = $Hostname.Split(",")[0]
		}
		
		if (!$Port)
		{
			$Port = "8080"
			$TaskPort = "8080"
		}
		else
		{
			$TaskPort = $Port.Split(",")[0]
		}
		
		if ($SSL)
		{
			if (!$SSLIP) 
			{
				$SSLIP = "127.0.0.1"
				
				if (!$SSLPort)
				{
					$SSLPort = "8443"
				}
			}
		}
		
		$CheckTask = schtasks.exe | where {$_ -like "PoSHServer-$TaskHostname-$TaskPort*"}
		if ($CheckTask)
		{
			Write-Warning "This job is already exist. You should run it from Scheduled Jobs."
			Write-Warning "Aborting.."
			Break;
		}
		else
		{
			# Prepare Job Information
			$TaskID = Get-Random -Maximum 10000
			$TaskName = "PoSHServer-$TaskHostname-$TaskPort-$TaskID"
			$CreateJobIDPath = $PoSHModulePath + "\jobs\job-" + $TaskID + ".txt"
			$CreateJobIDValue = $Hostname + ";" + $Port + ";" + $SSLIP + ";" + $SSLPort + ";" + $SSLName + ";" + $HomeDirectory + ";" + $LogDirectory + ";" + $CustomConfig + ";" + $CustomChildConfig + ";" + $CustomJob
			$CreateJobID = Add-Content -Path $CreateJobIDPath -Value $CreateJobIDValue
			
			# Create Scheduled Jobs
			$CreateTask = schtasks /create /tn "$TaskName" /xml "$PoSHModulePath\jobs\template.xml" /ru SYSTEM
			$ChangeTaskProcess = $true
			while ($ChangeTaskProcess)
			{
				if ($SSL)
				{
					$ChangeTask = schtasks /change /tn "$TaskName" /tr "Powershell -Command &{Import-Module PoSHServer; Start-PoSHServer -SSL -JobID $TaskID}" /rl highest
				}
				else
				{
					$ChangeTask = schtasks /change /tn "$TaskName" /tr "Powershell -Command &{Import-Module PoSHServer; Start-PoSHServer -JobID $TaskID}" /rl highest
				}
				
				if ($ChangeTask)
				{
					$ChangeTaskProcess = $false
				}
			}
			
			# Start Background Job
			$RunTask = schtasks /run /tn "$TaskName"
			
			# PoSH Server Welcome Banner
			Get-PoSHWelcomeBanner -Hostname $Hostname -Port $Port -SSL $SSL -SSLIP $SSLIP -SSLPort $SSLPort -DebugMode $DebugMode
			
			Break;
		}
	}
	
	# PoSH Server Background Jobs
	$PoSHJobArgs = @($Hostname,$Port,$HomeDirectory,$LogDirectory,$PoSHModulePath,$CustomJob,$asJob)
	$PoSHJob = Start-Job -scriptblock {
	param ($Hostname, $Port, $HomeDirectory, $LogDirectory, $PoSHModulePath, $CustomJob, $asJob)
	
		# Import PoSH Server Module
		Import-Module PoSHServer
		
		# Import Config
		. $PoSHModulePath\modules\config.ps1
		
		while ($true)
		{
			Start-Sleep -s 60						
			# Get Job Time			$JobTime = Get-Date -format HHmm			
			if ($LogSchedule -eq "Hourly")
			{
				# PoSH Server Log Hashing (at *:30 hourly)
				if ($JobTime -eq "*30")
				{
					New-PoSHLogHash -LogSchedule $LogSchedule -LogDirectory $LogDirectory
				}
			}
			else
			{
				# PoSH Server Log Hashing (at 02:30 daily)
				if ($JobTime -eq "0230")				{					New-PoSHLogHash -LogSchedule $LogSchedule -LogDirectory $LogDirectory				}
			}			
			# PoSH Server Custom Jobs (at every 5 minutes)			if ($JobTime -like "*5" -or $JobTime -like "*0")			{				if ($CustomJob)				{					. $CustomJob				}			}
		}
	} -ArgumentList $PoSHJobArgs		# PoSH Server Custom Config	if ($CustomConfig)	{		. $CustomConfig	}
	
	# Create an HTTPListener
	try
	{
		$Listener = New-Object Net.HttpListener
	}
	catch
	{
		Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
	}
	
	# Add Prefix Urls
	try
	{
		if (!$Hostname) 
		{
			$Hostname = "+"
			
			if (!$Port)
			{
				$Port = "8080"
			}
			
			$Prefix = "http://" + $Hostname + ":" + $Port + "/"
			$Listener.Prefixes.Add($Prefix)
		}
		else
		{
			$Hostnames = @($Hostname.Split(","))
			
			if (!$Port)
			{
				$Port = "8080"
			}
					
			foreach ($Hostname in $Hostnames)
			{
				$Prefix = "http://" + $Hostname + ":" + $Port + "/"
				$Listener.Prefixes.Add($Prefix)
			}
		}
		
		if ($SSL)
		{
			if (!$SSLIP) 
			{
				$SSLIP = "127.0.0.1"
				
				if (!$SSLPort)
				{
					$SSLPort = "8443"
				}
				
				$Prefix = "https://" + $SSLIP + ":" + $SSLPort + "/"
				$Listener.Prefixes.Add($Prefix)
			}
			else
			{
				$SSLIPAddresses = @($SSLIP.Split(","))
				
				if (!$SSLPort)
				{
					$SSLPort = "8443"
				}
						
				foreach ($SSLIPAddress in $SSLIPAddresses)
				{
					$Prefix = "https://" + $SSLIPAddress + ":" + $SSLPort + "/"
					$Listener.Prefixes.Add($Prefix)
				}
			}
		}		
	}
	catch
	{
		Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
	}
	
	# Start Listener
	try
	{
		$Listener.Start()
	}
	catch
	{
		Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
	}
	
	# Configure SSL
	try
	{
		if ($SSL)
		{
			if ($SSLName)
			{
				$PoSHCert = Get-ChildItem -Recurse Cert: | Where-Object { $_.FriendlyName -eq $SSLName }
				
				if ($PoSHCert)
				{
					$PoSHCert = Get-ChildItem -Recurse Cert: | Where-Object { $_.FriendlyName -eq "PoSHServer SSL Certificate" }
				}
			}
			else
			{
				$PoSHCert = Get-ChildItem -Recurse Cert: | Where-Object { $_.FriendlyName -eq "PoSHServer SSL Certificate" }
			}
			
			if (!$PoSHCert)
			{
				if ($DebugMode)
				{
					Add-Content -Value "Sorry, I couldn't find your SSL certificate." -Path "$LogDirectory\debug.txt"
					Add-Content -Value "Creating Self-Signed SSL certificate.." -Path "$LogDirectory\debug.txt"
				}
				Request-PoSHCertificate
				$PoSHCert = Get-ChildItem -Recurse Cert: | Where-Object { $_.FriendlyName -eq "PoSHServer SSL Certificate" }
			}
			
			# Register SSL Certificate
			$CertThumbprint = $PoSHCert[0].Thumbprint
			Register-PoSHCertificate -SSLIP $SSLIP -SSLPort $SSLPort -Thumbprint $CertThumbprint -DebugMode $DebugMode
		}
	}
	catch
	{
		Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
	}
	
	# PoSH Server Welcome Banner
	try
	{
		Get-PoSHWelcomeBanner -Hostname $Hostname -Port $Port -SSL $SSL -SSLIP $SSLIP -SSLPort $SSLPort -DebugMode $DebugMode
	}
	catch
	{
		Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
	}
	
	# PoSH Server Async Process Script
	$ScriptBlock = `
	{
	Param($Listener, $Hostname, $Hostnames, $HomeDirectory, $LogDirectory, $PoSHModulePath, $CustomChildConfig, $DebugMode)
		
		# Import PoSH Server Module
		Import-Module PoSHServer
		
		# Enable Debug Mode
		if ($DebugMode)
		{
			$DebugPreference = "Continue"
		}
		else
		{
			$ErrorActionPreference = "silentlycontinue"
		}
		
		# PHP Encoding Module
		. $PoSHModulePath\modules\phpencoding.ps1
		
		# PoSH Server Custom Child Config
		if ($CustomChildConfig)
		{
			. $CustomChildConfig
		}
		
		# Create loop
		$ShouldProcess = $true
		
		# Get Server Requests
		while ($ShouldProcess)
		{		
			# Open Connection
			$Context = $Listener.GetContext()			
						
			# Set Home Directory
			[IO.Directory]::SetCurrentDirectory("$HomeDirectory")
			$File = $Context.Request.Url.LocalPath
			$Response = $Context.Response
			$Response.Headers.Add("Accept-Encoding","gzip");
			$Response.Headers.Add("Server","PoSH Server");
			$Response.Headers.Add("X-Powered-By","Microsoft PowerShell");
			
			# Import Config
			. $PoSHModulePath\modules\config.ps1
			
			# Authentication Module
			. $PoSHModulePath\modules\authentication.ps1
			
			# Set Request Parameters
			$Request = $Context.Request
			$InputStream = $Request.InputStream
			$ContentEncoding = $Request.ContentEncoding
					
			# IP Restriction Module
			. $PoSHModulePath\modules\iprestriction.ps1
			
			# Get Query String
			$PoSHQuery = Get-PoSHQueryString -Request $Request
			
			# Get Post Stream
			$PoSHPost = Get-PoSHPostStream -InputStream $InputStream -ContentEncoding $ContentEncoding
			
			# Cookie Information
			$PoSHCookies = $Request.Cookies["PoSHSessionID"];
			if (!$PoSHCookies)
			{
				$PoSHCookie = New-Object Net.Cookie
				$PoSHCookie.Name = "PoSHSessionID"
				$PoSHCookie.Value = New-PoSHTimeStamp
				$Response.AppendCookie($PoSHCookie)
			}
			
			# Get Default Document
			if ($File -notlike "*.*" -and $File -like "*/")
			{
				$FolderPath = [System.IO.Directory]::GetCurrentDirectory() + $File
				$RequstURL = [string]$Request.Url
				$SubfolderName = $File
				$File = $File + $DefaultDocument
			}
			elseif ($File -notlike "*.*" -and $File -notlike "*/")
			{
				$FolderPath = [System.IO.Directory]::GetCurrentDirectory() + $File + "/"
				$RequstURL = [string]$Request.Url + "/"
				$SubfolderName = $File + "/"
				$File = $File + "/" + $DefaultDocument 
			}
			else
			{
				$FolderPath = $Null;
			}
			
			# PoSH API Support
			if ($File -like "*.psxml")
			{
				$File = $File.Replace(".psxml",".ps1")
				
				# Full File Path
				$File = [System.IO.Directory]::GetCurrentDirectory() + $File
				
				# Get Mime Type
				$MimeType = "text/psxml"
			}
			else
			{
				# Full File Path
				$File = [System.IO.Directory]::GetCurrentDirectory() + $File
				
				# Get Mime Type
				$FileExtension = (Get-ChildItem $File -EA SilentlyContinue).Extension
				$MimeType = Get-MimeType $FileExtension
			}
			
			# Content Filtering Module
			. $PoSHModulePath\modules\contentfiltering.ps1
			
			# Stream Content
			if ([System.IO.File]::Exists($File) -and $ContentSessionDrop -eq "0" -and $IPSessionDrop -eq "0")  
			{ 
				if ($MimeType -eq "text/ps1")
				{
					try
					{
						$Response.ContentType = "text/html"
						$Response.StatusCode = [System.Net.HttpStatusCode]::OK
						$LogResponseStatus = $Response.StatusCode
						$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
						$Response.WriteLine("$(. $File)")
					}
					catch
					{
						Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
					}
				}
				elseif ($MimeType -eq "text/psxml")
				{
					try
					{
						$Response.ContentType = "text/xml"
						$Response.StatusCode = [System.Net.HttpStatusCode]::OK
						$LogResponseStatus = $Response.StatusCode
						$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
						$Response.WriteLine("$(. $File)")
					}
					catch
					{
						Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
					}
				}
				elseif ($MimeType -eq "text/php")
				{
					try
					{
						if ($PHPCgiPath)
						{
							$TestPHPCgiPath = Test-Path -Path $PHPCgiPath
						}
						else
						{
							$TestPHPCgiPath = $false
						}
						
						if ($TestPHPCgiPath)
						{
							if ($File -like "C:\Windows\*")
							{
								$Response.ContentType = "text/html"
								$Response.StatusCode = [System.Net.HttpStatusCode]::NotFound
								$LogResponseStatus = $Response.StatusCode
								$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
								$Response.WriteLine("$(. $PoSHModulePath\modules\phpsecurityerror.ps1)")
							}
							else
							{
								$Response.ContentType = "text/html"
								$PHPQuery = Get-PoSHPHPQuery -PoSHPHPGET $PoSHQuery.PoSHQueryString -PoSHPHPPOST $PoSHPost.PoSHPostStream
								$PHPContentOutput = Get-PoSHPHPContent -File "$File" -QueryString "$PHPQuery" -PHPCgiPath "$PHPCgiPath"
								$PHPContentOutput = Set-PHPEncoding -PHPOutput $PHPContentOutput
								$Response.StatusCode = [System.Net.HttpStatusCode]::OK
								$LogResponseStatus = $Response.StatusCode
								$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
								$Response.WriteLine("$PHPContentOutput")	
							}
						}
						else
						{
							$Response.ContentType = "text/html"
							$Response.StatusCode = [System.Net.HttpStatusCode]::NotFound
							$LogResponseStatus = $Response.StatusCode
							$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
							$Response.WriteLine("$(. $PoSHModulePath\modules\phpcgierror.ps1)")						
						}
					}
					catch
					{
						Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
					}
				}				
				else
				{
					try
					{
						$Response.ContentType = "$MimeType"
						$FileContent = [System.IO.File]::ReadAllBytes($File)
						$Response.ContentLength64 = $FileContent.Length
						$Response.StatusCode = [System.Net.HttpStatusCode]::OK
						$LogResponseStatus = $Response.StatusCode
						$Response.OutputStream.Write($FileContent, 0, $FileContent.Length)
					}
					catch
					{
						Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
					}
				}
			}
			else
			{
				# Content Filtering and IP Restriction Control
				if ($ContentSessionDrop -eq "0" -and $IPSessionDrop -eq "0")
				{
					if ($FolderPath)
					{
						$TestFolderPath = Test-Path -Path $FolderPath
					}
					else
					{
						$TestFolderPath = $false
					}
				}
				else
				{
					$TestFolderPath = $false
				}
				
				if ($DirectoryBrowsing -eq "On" -and $TestFolderPath)
				{
					try
					{
						$Response.ContentType = "text/html"
						$Response.StatusCode = [System.Net.HttpStatusCode]::OK
						$LogResponseStatus = $Response.StatusCode
						$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
						if ($Hostname -eq "+") { $HeaderName = "localhost" } else { $HeaderName = $Hostnames[0] }
						$DirectoryContent = (Get-DirectoryContent -Path "$FolderPath" -HeaderName $HeaderName -RequestURL $RequestURL -SubfolderName $SubfolderName)
						$Response.WriteLine("$DirectoryContent")
					}
					catch
					{
						Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
					}
				}
				else
				{
					try
					{
						$Response.ContentType = "text/html"
						$Response.StatusCode = [System.Net.HttpStatusCode]::NotFound
						$LogResponseStatus = $Response.StatusCode
						$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
						$Response.WriteLine("$(. $PoSHModulePath\modules\notfound.ps1)")
					}
					catch
					{
						Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
					}
				}
			}
			
			# Logging Module
			. $PoSHModulePath\modules\log.ps1
			
			# Close Connection
			try
			{
				$Response.Close()
			}
			catch
			{
				Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
			}
		}	
	}
	
	if ($DebugMode)
	{	
		# Invoke PoSH Server Multithread Process - Thread 1
		Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig -DebugMode | Out-Null
		
		# Invoke PoSH Server Multithread Process - Thread 2
		Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig -DebugMode | Out-Null
		
		# Invoke PoSH Server Multithread Process - Thread 3
		Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig -DebugMode | Out-Null
	}
	else
	{
		# Invoke PoSH Server Multithread Process - Thread 1
		Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig | Out-Null
		
		# Invoke PoSH Server Multithread Process - Thread 2
		Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig | Out-Null
		
		# Invoke PoSH Server Multithread Process - Thread 3
		Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig | Out-Null
	}
	
	# Create loop
	$ShouldProcess = $true
	
	# Get Server Requests
	while ($ShouldProcess)
	{		
		# Open Connection
		$Context = $Listener.GetContext()			
					
		# Set Home Directory
		[IO.Directory]::SetCurrentDirectory("$HomeDirectory")
		$File = $Context.Request.Url.LocalPath
		$Response = $Context.Response
		$Response.Headers.Add("Accept-Encoding","gzip");
		$Response.Headers.Add("Server","PoSH Server");
		$Response.Headers.Add("X-Powered-By","Microsoft PowerShell");
		
		# Import Config
		. $PoSHModulePath\modules\config.ps1
		
		# Authentication Module
		. $PoSHModulePath\modules\authentication.ps1
		
		# Set Request Parameters
		$Request = $Context.Request
		$InputStream = $Request.InputStream
		$ContentEncoding = $Request.ContentEncoding
				
		# IP Restriction Module
		. $PoSHModulePath\modules\iprestriction.ps1
		
		# Get Query String
		$PoSHQuery = Get-PoSHQueryString -Request $Request
		
		# Get Post Stream
		$PoSHPost = Get-PoSHPostStream -InputStream $InputStream -ContentEncoding $ContentEncoding
		
		# Cookie Information
		$PoSHCookies = $Request.Cookies["PoSHSessionID"];
		if (!$PoSHCookies)
		{
			$PoSHCookie = New-Object Net.Cookie
			$PoSHCookie.Name = "PoSHSessionID"
			$PoSHCookie.Value = New-PoSHTimeStamp
			$Response.AppendCookie($PoSHCookie)
		}
		
		# Get Default Document
		if ($File -notlike "*.*" -and $File -like "*/")
		{
			$FolderPath = [System.IO.Directory]::GetCurrentDirectory() + $File
			$RequstURL = [string]$Request.Url
			$SubfolderName = $File
			$File = $File + $DefaultDocument
		}
		elseif ($File -notlike "*.*" -and $File -notlike "*/")
		{
			$FolderPath = [System.IO.Directory]::GetCurrentDirectory() + $File + "/"
			$RequstURL = [string]$Request.Url + "/"
			$SubfolderName = $File + "/"
			$File = $File + "/" + $DefaultDocument 
		}
		else
		{
			$FolderPath = $Null;
		}
		
		# PoSH API Support
		if ($File -like "*.psxml")
		{
			$File = $File.Replace(".psxml",".ps1")
			
			# Full File Path
			$File = [System.IO.Directory]::GetCurrentDirectory() + $File
			
			# Get Mime Type
			$MimeType = "text/psxml"
		}
		else
		{
			# Full File Path
			$File = [System.IO.Directory]::GetCurrentDirectory() + $File
			
			# Get Mime Type
			$FileExtension = (Get-ChildItem $File -EA SilentlyContinue).Extension
			$MimeType = Get-MimeType $FileExtension
		}
		
		# Content Filtering Module
		. $PoSHModulePath\modules\contentfiltering.ps1
		
		# Stream Content
		if ([System.IO.File]::Exists($File) -and $ContentSessionDrop -eq "0" -and $IPSessionDrop -eq "0")  
		{ 
			if ($MimeType -eq "text/ps1")
			{
				try
				{
					$Response.ContentType = "text/html"
					$Response.StatusCode = [System.Net.HttpStatusCode]::OK
					$LogResponseStatus = $Response.StatusCode
					$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
					$Response.WriteLine("$(. $File)")
				}
				catch
				{
					Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
				}
			}
			elseif ($MimeType -eq "text/psxml")
			{
				try
				{
					$Response.ContentType = "text/xml"
					$Response.StatusCode = [System.Net.HttpStatusCode]::OK
					$LogResponseStatus = $Response.StatusCode
					$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
					$Response.WriteLine("$(. $File)")
				}
				catch
				{
					Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
				}
			}
			elseif ($MimeType -eq "text/php")
			{
				try
				{
					if ($PHPCgiPath)
					{
						$TestPHPCgiPath = Test-Path -Path $PHPCgiPath
					}
					else
					{
						$TestPHPCgiPath = $false
					}
					
					if ($TestPHPCgiPath)
					{
						if ($File -like "C:\Windows\*")
						{
							$Response.ContentType = "text/html"
							$Response.StatusCode = [System.Net.HttpStatusCode]::NotFound
							$LogResponseStatus = $Response.StatusCode
							$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
							$Response.WriteLine("$(. $PoSHModulePath\modules\phpsecurityerror.ps1)")
						}
						else
						{
							$Response.ContentType = "text/html"
							$PHPQuery = Get-PoSHPHPQuery -PoSHPHPGET $PoSHQuery.PoSHQueryString -PoSHPHPPOST $PoSHPost.PoSHPostStream
							$PHPContentOutput = Get-PoSHPHPContent -File "$File" -QueryString "$PHPQuery" -PHPCgiPath "$PHPCgiPath"
							$PHPContentOutput = Set-PHPEncoding -PHPOutput $PHPContentOutput
							$Response.StatusCode = [System.Net.HttpStatusCode]::OK
							$LogResponseStatus = $Response.StatusCode
							$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
							$Response.WriteLine("$PHPContentOutput")
						}
					}
					else
					{
						$Response.ContentType = "text/html"
						$Response.StatusCode = [System.Net.HttpStatusCode]::NotFound
						$LogResponseStatus = $Response.StatusCode
						$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
						$Response.WriteLine("$(. $PoSHModulePath\modules\phpcgierror.ps1)")						
					}
				}
				catch
				{
					Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
				}
			}				
			else
			{
				try
				{
					$Response.ContentType = "$MimeType"
					$FileContent = [System.IO.File]::ReadAllBytes($File)
					$Response.ContentLength64 = $FileContent.Length
					$Response.StatusCode = [System.Net.HttpStatusCode]::OK
					$LogResponseStatus = $Response.StatusCode
					$Response.OutputStream.Write($FileContent, 0, $FileContent.Length)
				}
				catch
				{
					Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
				}
			}
		}
		else
		{
			# Content Filtering and IP Restriction Control
			if ($ContentSessionDrop -eq "0" -and $IPSessionDrop -eq "0")
			{
				if ($FolderPath)
				{
					$TestFolderPath = Test-Path -Path $FolderPath
				}
				else
				{
					$TestFolderPath = $false
				}
			}
			else
			{
				$TestFolderPath = $false
			}
			
			if ($DirectoryBrowsing -eq "On" -and $TestFolderPath)
			{
				try
				{
					$Response.ContentType = "text/html"
					$Response.StatusCode = [System.Net.HttpStatusCode]::OK
					$LogResponseStatus = $Response.StatusCode
					$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
					if ($Hostname -eq "+") { $HeaderName = "localhost" } else { $HeaderName = $Hostnames[0] }
					$DirectoryContent = (Get-DirectoryContent -Path "$FolderPath" -HeaderName $HeaderName -RequestURL $RequestURL -SubfolderName $SubfolderName)
					$Response.WriteLine("$DirectoryContent")
				}
				catch
				{
					Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
				}
			}
			else
			{
				try
				{
					$Response.ContentType = "text/html"
					$Response.StatusCode = [System.Net.HttpStatusCode]::NotFound
					$LogResponseStatus = $Response.StatusCode
					$Response = New-Object IO.StreamWriter($Response.OutputStream,[Text.Encoding]::UTF8)
					$Response.WriteLine("$(. $PoSHModulePath\modules\notfound.ps1)")
				}
				catch
				{
					Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
				}
			}
		}
		
		# Logging Module
		. $PoSHModulePath\modules\log.ps1
		
		# Close Connection
		try
		{
			$Response.Close()
		}
		catch
		{
			Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
		}
	}
	
	# Stop Listener
	$Listener.Stop()
}