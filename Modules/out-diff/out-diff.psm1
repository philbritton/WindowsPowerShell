function Out-Diff {
<#
.Synopsis
    Redirects a Universal DIFF encoded text from the pipeline to the host using colors to highlight the differences.
.Description
    Helper function to highlight the differences in a Universal DIFF text using color coding.
.Parameter InputObject
    The text to display as Universal DIFF.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [PSObject]$InputObject
)
    Process {
        $contentLine = $InputObject | Out-String
        if ($contentLine -match "^Index:") {
            Write-Host $contentLine -ForegroundColor Cyan -NoNewline
        } elseif ($contentLine -match "^(\+|\-|\=){3}") {
            Write-Host $contentLine -ForegroundColor Gray -NoNewline
        } elseif ($contentLine -match "^\@{2}") {
            Write-Host $contentLine -ForegroundColor Gray -NoNewline
        } elseif ($contentLine -match "^\+") {
            Write-Host $contentLine -ForegroundColor Green -NoNewline
        } elseif ($contentLine -match "^\-") {
            Write-Host $contentLine -ForegroundColor Red -NoNewline
        } else {
            Write-Host $contentLine -NoNewline
        }
    }
}