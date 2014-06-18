add-type -AssemblyName system.runtime.serialization
if("System.Runtime.Serialization.Json.JsonReaderWriterFactory" -as [Type]) { 

   function FindModule {
      [CmdletBinding()]
      param(
         # Term to Search for (defaults to find "all" modules)
         [string]$SearchTerm,

         # Search for modules published by a particular author.
         [Parameter(Mandatory=$true)]
         [string]$Author,

         # Search for a specific module.
         [Parameter(Mandatory=$true)]
         [string]$ModuleName,

         $Root = "https://api.github.com/search/code"
      )


      if($Author -and $ModuleName) # SAM,AM
      {
         $search = "$SearchTerm @$Author/$ModuleName "
      }
      elseif($Author) # A,AS
      {
         $search = "$SearchTerm @$Author "
      }
      elseif($ModuleName) #M,MS
      {
         $search = "$SearchTerm $ModuleName "
      }
      elseif($SearchTerm) # S
      {
         $search = "$SearchTerm "
      }
      else 
      {
         $search = ""
      }
    
      Write-Verbose "q=${search}path:package.psd1"
      
      Add-Type -AssemblyName System.Web.Extensions

      # Note: while in preview, the GitHub api requires an "Accept" header as acknowledgement of it's beta status.
      $wr = Invoke-WebRequest $Root -Body @{q="$search path:package.psd1"} -Headers @{Accept='application/vnd.github.preview'}
      # Read the data using the right character set, because Invoke-WebRequest doesn't
      try {
         $null = $wr.RawContentStream.Seek(0,"Begin")
         $reader = New-Object System.IO.StreamReader $wr.RawContentStream, $wr.BaseResponse.CharacterSet
         $content = $reader.ReadToEnd()
      } catch {
         $content= $wr.Content
      } finally {
         if($reader) { $reader.Close() }
      }

      $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
      $json = $ser.DeserializeObject($Content)

      $json.items | %{
         $result = New-Object psobject -Property @{
            'Author'=$_.repository.owner.login
            'ModuleName'=$_.repository.name
            'Description'=$_.repository.description
            # The PackageManifestUri should point at the raw version of the html_url so tools can download it
            'PackageManifestUri'=$_.html_url -replace "(https?://)",'$1raw.' -replace "/blob",""

            'SourceRepoUri'=$_.repository.html_url
            'Repository' = @{ GitHub = $Root }
         }
         $result.pstypenames.Insert(0,'PoshCode.ModuleInfo')
         $result.pstypenames.Insert(0,'PoshCode.Search.ModuleInfo')         
         $result.pstypenames.Insert(0,'PoshCode.Search.Github.ModuleInfo')
         if($ModuleName)
         {
            $result | Where-Object { $_.Name -eq $ModuleName }
         }
         else
         {
            $result
         }
      }
   }

   Export-ModuleMember -Function FindModule

}
else { write-Warning "Github Searching is unavailable because it requires the JavaScriptSerializer from .Net 3.5" }


# SIG # Begin signature block
# MIIarwYJKoZIhvcNAQcCoIIaoDCCGpwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+yG3w9kl20hGJ40M3qEBtxcn
# wY2gghXlMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggahMIIFiaADAgECAhADS1DyPKUAAEvdY0qN2NEFMA0GCSqGSIb3DQEBBQUAMG8x
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29k
# ZSBTaWduaW5nIENBLTEwHhcNMTMwMzE5MDAwMDAwWhcNMTQwNDAxMTIwMDAwWjBt
# MQswCQYDVQQGEwJVUzERMA8GA1UECBMITmV3IFlvcmsxFzAVBgNVBAcTDldlc3Qg
# SGVucmlldHRhMRgwFgYDVQQKEw9Kb2VsIEguIEJlbm5ldHQxGDAWBgNVBAMTD0pv
# ZWwgSC4gQmVubmV0dDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMPj
# sSDplpNPrcGhb5o977Z7VdTm/BdBokBbRRD5hGF+E7bnIOEK2FTB9Wypgp+9udd7
# 6nMgvZpj4gtO6Yj+noUcK9SPDMWgVOvvOe5JKKJArRvR5pDuHKFa+W2zijEWUjo5
# DcqU2PGDralKrBZVfOonity/ZHMUpieezhqy98wcK1PqDs0Cm4IeRDcbNwF5vU1T
# OAwzFoETFzPGX8n37INVIsV5cFJ1uGFncvRbAHVbwaoR1et0o01Jsb5vYUmAhb+n
# qL/IA/wOhU8+LGLhlI2QL5USxnLwxt64Q9ZgO5vu2C2TxWEwnuLz24SAhHl+OYom
# tQ8qQDJQcfh5cGOHlCsCAwEAAaOCAzkwggM1MB8GA1UdIwQYMBaAFHtozimqwBe+
# SXrh5T/Wp/dFjzUyMB0GA1UdDgQWBBRfhbxO+IGnJ/yiJPFIKOAXo+DUWTAOBgNV
# HQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwcwYDVR0fBGwwajAzoDGg
# L4YtaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL2Fzc3VyZWQtY3MtMjAxMWEuY3Js
# MDOgMaAvhi1odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vYXNzdXJlZC1jcy0yMDEx
# YS5jcmwwggHEBgNVHSAEggG7MIIBtzCCAbMGCWCGSAGG/WwDATCCAaQwOgYIKwYB
# BQUHAgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9y
# eS5odG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYA
# IAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkA
# dAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAA
# RABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAA
# UgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAA
# dwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4A
# ZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkA
# bgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wgYIGCCsGAQUFBwEBBHYwdDAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEwGCCsGAQUFBzAC
# hkBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURD
# b2RlU2lnbmluZ0NBLTEuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEFBQAD
# ggEBABv8O1PicJ3pbsLtls/jzFKZIG16h2j0eXdsJrGZzx6pBVnXnqvL4ZrF6dgv
# puQWr+lg6wL+Nxi9kJMeNkMBpmaXQtZWuj6lVx23o4k3MQL5/Kn3bcJGpdXNSEHS
# xRkGFyBopLhH2We/0ic30+oja5hCh6Xko9iJBOZodIqe9nITxBjPrKXGUcV4idWj
# +ZJtkOXHZ4ucQ99f7aaM3so30IdbIq/1+jVSkFuCp32fisUOIHiHbl3nR8j20YOw
# ulNn8czlDjdw1Zp/U1kNF2mtZ9xMYI8yOIc2xvrOQQKLYecricrgSMomX54pG6uS
# x5/fRyurC3unlwTqbYqAMQMlhP8wggajMIIFi6ADAgECAhAPqEkGFdcAoL4hdv3F
# 7G29MA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0Rp
# Z2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMTAyMTExMjAwMDBaFw0yNjAy
# MTAxMjAwMDBaMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTEwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQCcfPmgjwrKiUtTmjzsGSJ/DMv3SETQPyJumk/6zt/G0ySR/6hS
# k+dy+PFGhpTFqxf0eH/Ler6QJhx8Uy/lg+e7agUozKAXEUsYIPO3vfLcy7iGQEUf
# T/k5mNM7629ppFwBLrFm6aa43Abero1i/kQngqkDw/7mJguTSXHlOG1O/oBcZ3e1
# 1W9mZJRru4hJaNjR9H4hwebFHsnglrgJlflLnq7MMb1qWkKnxAVHfWAr2aFdvftW
# k+8b/HL53z4y/d0qLDJG2l5jvNC4y0wQNfxQX6xDRHz+hERQtIwqPXQM9HqLckvg
# VrUTtmPpP05JI+cGFvAlqwH4KEHmx9RkO12rAgMBAAGjggNDMIIDPzAOBgNVHQ8B
# Af8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwggHDBgNVHSAEggG6MIIBtjCC
# AbIGCGCGSAGG/WwDMIIBpDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5kaWdpY2Vy
# dC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwICMIIBVh6C
# AVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBp
# AGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABh
# AG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBD
# AFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5
# ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABs
# AGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABv
# AHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBj
# AGUALjASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQW
# BBR7aM4pqsAXvkl64eU/1qf3RY81MjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYun
# pyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAe3IdZP+IyDrBt+nnqcSHu9uUkteQ
# WTP6K4feqFuAJT8Tj5uDG3xDxOaM3zk+wxXssNo7ISV7JMFyXbhHkYETRvqcP2pR
# ON60Jcvwq9/FKAFUeRBGJNE4DyahYZBNur0o5j/xxKqb9to1U0/J8j3TbNwj7aqg
# TWcJ8zqAPTz7NkyQ53ak3fI6v1Y1L6JMZejg1NrRx8iRai0jTzc7GZQY1NWcEDzV
# sRwZ/4/Ia5ue+K6cmZZ40c2cURVbQiZyWo0KSiOSQOiG3iLCkzrUm2im3yl/Brk8
# Dr2fxIacgkdCcTKGCZlyCXlLnXFp9UH/fzl3ZPGEjb6LHrJ9aKOlkLEM/zGCBDQw
# ggQwAgEBMIGDMG8xCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBLTECEANLUPI8pQAAS91jSo3Y0QUwCQYF
# Kw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJ
# KoZIhvcNAQkEMRYEFLfLNwxssfADfKc2QxA06FzrcSWhMA0GCSqGSIb3DQEBAQUA
# BIIBAJc3/jNyX71KKAn0BKjsJlXcEGOZQhkjbimRvf1U0pbxSMT4l93h2A9VZKiM
# H/+oYbZPr6MNJ1mj6Jbu9XCn4vOBjY+pDvr3u6uwAwiTaOtu0cWlcYXOmWm0gbhj
# grFvKvvmMvO0h1NID9OezuDYz1ra9q1z0WbSdQkkeakFY0BYVSZf/Focuo+1PmrC
# kbgC4lDswZSYK/pSnrBL9KMFo8TK1YBnwHtGW+1G1h8bYPYOQqvZ40ytmlmbcuDZ
# wu3AwtnF01CjhcxwjEJMSgOJfVabzv+aMFm0MpLCZFnpvouEN8fkyCB1SCo/RElD
# dmYF3CKhX7O4N4/GlJRhQomoRmyhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQC
# AQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0Eg
# LSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTMxMTA0MDcxOTM5WjAjBgkq
# hkiG9w0BCQQxFgQUMz4arG+vvWQBy1E4md5TkW1NEZwwDQYJKoZIhvcNAQEBBQAE
# ggEAUMXGU3KXtAZiAvQ22Qt7ERDpE1S75WLCeHLbUiCXin1omknxmnU62dn97jnW
# a1JKuaX7GTAQx1v66/E6DtCuQ5EsJ/R5Wc7r2O+e16aTp4pmXswUo1duAiZvs2+F
# uWbh4ejlZkpjEg/lCMceYZqS/gGgA0KN0gRuQNmqZa5rmTwa+Os9DTWXBQeZb+5g
# 7CU7WPpi8iYJo0qRiw4r1OC4sytuVG50lOoVMiiFQdfB3Efg1xisU4JpLc0WqxsU
# n+rut/UKUxqmM8UUYfL23fXWQzTIb//navBlduZST06fZNXXN3I1yJniFv99N5Qr
# 6+RyPRzkXoEZsUjx84c9ztSHNw==
# SIG # End signature block
