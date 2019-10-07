[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string] $PackerLog
)

$content = Get-Content -Path $PackerLog -Raw
$vhdUrl = ""

if($content -match "(?m)^OSDiskUri: (.*)$") {
    $vhdUrl = $Matches[1]
}

if ([string]::IsNullOrEmpty($vhdUrl)) {
    throw "VHD URI was not found in image.txt"
}

Write-Output "##vso[task.setvariable variable=OsDiskLocation]$($vhdUrl)"