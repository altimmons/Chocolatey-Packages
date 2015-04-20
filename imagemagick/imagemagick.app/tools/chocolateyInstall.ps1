﻿$packageName = 'imagemagick.app'
$installerType = 'exe'
$url = 'http://www.imagemagick.org/download/binaries/ImageMagick-6.9.1-2-Q16-x86-dll.exe'
$url64 = 'http://www.imagemagick.org/download/binaries/ImageMagick-6.9.1-2-Q16-x64-dll.exe'
$silentArgs = '/VERYSILENT'
$validExitCodes = @(0)

if ($env:chocolateyPackageParameters) {
    $packageParams = ConvertFrom-StringData $env:chocolateyPackageParameters.Replace(" ", "`n")
    if ($packageParams.InstallDevelopmentHeaders) {
        $silentArgs = $silentArgs + ' /MERGETASKS=install_devel'
    }
}

try {
    # Uninstall older version of imagemagick, otherwise the installation won’t be silent.
    $regPath = 'HKLM:\SOFTWARE\ImageMagick\Current'
    if ($env:chocolateyForceX86) {
        $regPath = 'HKLM:\SOFTWARE\Wow6432Node\ImageMagick\Current'
    }
    if (Test-Path $regPath) {
        $uninstallPath = (Get-ItemProperty -Path $regPath).BinPath
        $uninstallFilePath = "$uninstallPath\unins000.exe"
        Uninstall-ChocolateyPackage $packageName $installerType $silentArgs $uninstallFilePath
    }
} catch {
    Write-Warning "$packageName uninstallation failed, with message $($_.Exception.Message)"
    Write-Warning "$packageName installation may not be silent"
}

try {
    Write-Verbose "Installing with arguments: $silentArgs"
    Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" "$url" "$url64"  -validExitCodes $validExitCodes
}
catch {
    try {
        $tempDir = "$env:TEMP\chocolatey\$packageName"
        if (-not (Test-Path $tempDir)) {New-Item $tempDir -ItemType directory}

        $listUrl = 'http://www.imagemagick.org/download/binaries/'
        $fileFullPath = "$tempDir\temp.html"

        # Obtain the download URL of the latest version using regex
        Get-ChocolateyWebFile 'HTML file containing the URL' $fileFullPath $listUrl
        $content = Select-String -Path $fileFullPath -Pattern '-Q16-x86-dll.exe' | Select-Object -First 1
        $content64 = Select-String -Path $fileFullPath -Pattern '-Q16-x64-dll.exe' | Select-Object -First 1
        $url = $content -replace '.+(ImageMagick-)([\d-\.]+)(-Q16-x86-dll.exe).+', 'http://www.imagemagick.org/download/binaries/$1$2$3'
        $url64 = $content64 -replace '.+(ImageMagick-)([\d-\.]+)(-Q16-x64-dll.exe).+', 'http://www.imagemagick.org/download/binaries/$1$2$3'

        Install-ChocolateyPackage $packageName $installerType $silentArgs $url $url64  -validExitCodes $validExitCodes
    } catch {
        Write-ChocolateyFailure $packageName "$($_.Exception.Message)"
        throw 
    }
}