# Run packer to build VS2017-Server-Azure image in specified Azure Subscription

$packerSourceUrl = 'https://releases.hashicorp.com/packer/1.3.5/packer_1.3.5_windows_amd64.zip'

$basePath = Split-Path -Path $PSScriptRoot -Parent
$packerBinFolder = $env:BUILD_BINARIESDIRECTORY
if ([string]::IsNullOrEmpty($packerBinFolder)) {
    $packerBinFolder = $env:TEMP
}

$packerTemplate = Join-Path -Path $basePath -ChildPath 'images\win\vs2017-Server2016-Azure.json'

try {
    # Downloads Packer

    $packerZipPath = Join-Path -Path $packerBinFolder -ChildPath 'packer.zip'
    $packerExecutable = Join-Path -Path $packerBinFolder -ChildPath 'packer.exe'
    $packerLog = Join-Path -Path $packerBinFolder -ChildPath 'packer.log'
    $outputFile = Join-Path -Path $packerBinFolder -ChildPath 'ImageOutput.txt'

    if (Test-Path $packerZipPath) {
        Remove-Item $packerZipPath -Force
    }

    if (Test-Path $outputFile) {
        Remove-Item $outputFile -Force
    }

    Write-Output "Downloading Packer from $packerSourceUrl"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $packerSourceUrl -UseBasicParsing -OutFile $packerZipPath

    Write-Output "Expanding $packerZipPath"
    Expand-Archive -Path $packerZipPath -DestinationPath $packerBinFolder -Force

    # Run Packer

    Write-Output "Starting packer..."
    try {
        Start-Transcript -Path $packerLog
        & $packerExecutable build  --var-file="$($basePath)/build_variables.json" "$($packerTemplate)" | Out-Default
    }
    finally {
        Stop-Transcript -ErrorAction SilentlyContinue
    }

    if ($LASTEXITCODE -ne 0)
    {
        $err = "Packer returned exit code $LASTEXITCODE."
        throw $err
    }

    # Read VHD URI
	Write-Output "Reading VHD URI."
    $logContent = Get-Content -Path $packerLog -Tail 100
    $vhdUri = $null
    foreach ($line in $logContent) {
        if ($line -like 'OSDiskUri:*') {
            $vhdUri = $line
            break
        }
    }

    if ($null -eq $vhdUri) {
        throw 'OS Disk was not created.'
    }

    Set-Content -Path $outputFile -Value $vhdUri -Force
}
catch {
    throw
}
