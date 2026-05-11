# STM32 VSCode Toolchain Setup Script for Windows
# This script downloads and extracts ARM GCC and OpenOCD to the ./tools directory

$toolsDir = "$PSScriptRoot\tools"
$gccUrl = "https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v13.3.1-1.1/xpack-arm-none-eabi-gcc-13.3.1-1.1-win32-x64.zip"
$gccZip = "$toolsDir\gcc.zip"
$openocdUrl = "https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-4/xpack-openocd-0.12.0-4-win32-x64.zip"
$openocdZip = "$toolsDir\openocd.zip"

# Create tools directory
if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
}

function Download-File($url, $output, $name) {
    if (Test-Path $output) {
        Write-Host "$name zip already exists, skipping download."
        return $true
    }
    Write-Host "Downloading $name ..."
    Write-Host "URL: $url"

    # Try curl.exe first (more reliable on Windows for GitHub)
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        & curl.exe -L -o "$output" --retry 3 --retry-delay 5 "$url" 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path $output) -and (Get-Item $output).Length -gt 1000000) {
            Write-Host "$name downloaded successfully with curl."
            return $true
        }
    }

    # Fallback to Invoke-WebRequest (compatible with older PowerShell)
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -TimeoutSec 120
        if ((Test-Path $output) -and (Get-Item $output).Length -gt 1000000) {
            Write-Host "$name downloaded successfully."
            return $true
        }
    } catch {
        Write-Warning "Failed to download $name`: $_"
    }

    Write-Warning "$name download failed. Please manually download the zip and place it at: $output"
    return $false
}

function Extract-Zip($zip, $dest, $name) {
    if (-not (Test-Path $zip)) {
        Write-Warning "Cannot extract $name`: $zip not found."
        return $false
    }
    Write-Host "Extracting $name ..."
    try {
        Expand-Archive -Path $zip -DestinationPath $dest -Force
        Remove-Item $zip -ErrorAction SilentlyContinue
        Write-Host "$name extracted successfully."
        return $true
    } catch {
        Write-Warning "Failed to extract $name`: $_"
        return $false
    }
}

# Download and extract ARM GCC
$gccOk = $false
if (-not (Test-Path "$toolsDir\xpack-arm-none-eabi-gcc-*")) {
    if (Download-File $gccUrl $gccZip "ARM GCC") {
        $gccOk = Extract-Zip $gccZip $toolsDir "ARM GCC"
    }
} else {
    Write-Host "ARM GCC already extracted, skipping."
    $gccOk = $true
}

# Download and extract OpenOCD
$openocdOk = $false
if (-not (Test-Path "$toolsDir\xpack-openocd-*")) {
    if (Download-File $openocdUrl $openocdZip "OpenOCD") {
        $openocdOk = Extract-Zip $openocdZip $toolsDir "OpenOCD"
    }
} else {
    Write-Host "OpenOCD already extracted, skipping."
    $openocdOk = $true
}

# Detect installed paths
$gccPath = (Get-ChildItem -Path $toolsDir -Filter "xpack-arm-none-eabi-gcc-*" -Directory | Select-Object -First 1).FullName
$openocdPath = (Get-ChildItem -Path $toolsDir -Filter "xpack-openocd-*" -Directory | Select-Object -First 1).FullName

Write-Host ""
Write-Host "========================================"
if ($gccOk -and $openocdOk) {
    Write-Host "Installation complete!"
} else {
    Write-Host "Installation incomplete - see warnings above."
}
Write-Host "========================================"
Write-Host ""

if ($gccPath) {
    Write-Host "ARM GCC path: $gccPath\bin"
} else {
    Write-Host "ARM GCC: NOT FOUND"
}
if ($openocdPath) {
    Write-Host "OpenOCD path: $openocdPath\bin"
} else {
    Write-Host "OpenOCD: NOT FOUND"
}

if ($gccPath -and $openocdPath) {
    Write-Host ""
    Write-Host "Add these to your system PATH:"
    Write-Host "  1. $gccPath\bin"
    Write-Host "  2. $openocdPath\bin"
    Write-Host ""
    Write-Host "Or run this command in your current terminal to use them temporarily:"
    Write-Host ('  $env:Path += ";' + $gccPath + '\bin;' + $openocdPath + '\bin"')
}

Write-Host ""
Write-Host "Then verify with:"
Write-Host "  arm-none-eabi-gcc --version"
Write-Host "  openocd --version"
Write-Host ""
Read-Host "Press Enter to exit"
