#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build script for KC-Device firmware supporting ESP32-S3 and ESP32-C6 targets

.DESCRIPTION
    This script simplifies building, flashing, and monitoring the KC-Device firmware
    for different ESP32 chip variants. It automatically manages separate build
    directories and SDK configurations for each target.

.PARAMETER Target
    The ESP32 chip target: 's3' (ESP32-S3) or 'c6' (ESP32-C6)

.PARAMETER Action
    The action to perform: 'build', 'flash', 'monitor', 'clean', 'fullclean', 'menuconfig', or 'all'

.PARAMETER Port
    COM port for flashing (e.g., COM3). If not specified, idf.py will auto-detect

.EXAMPLE
    .\build.ps1 -Target s3 -Action build
    Build firmware for ESP32-S3

.EXAMPLE
    .\build.ps1 -Target c6 -Action all -Port COM3
    Build and flash firmware for ESP32-C6 on COM3

.EXAMPLE
    .\build.ps1 -Target s3 -Action monitor -Port COM3
    Monitor serial output from ESP32-S3 on COM3
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet('s3', 'c6', 'S3', 'C6')]
    [string]$Target,

    [Parameter(Mandatory=$false, Position=1)]
    [ValidateSet('build', 'flash', 'monitor', 'clean', 'fullclean', 'menuconfig', 'all')]
    [string]$Action = 'build',

    [Parameter(Mandatory=$false)]
    [string]$Port = ""
)

# Normalize target to lowercase
$Target = $Target.ToLower()

# Configuration mapping
$config = @{
    's3' = @{
        Name = 'ESP32-S3'
        BuildDir = 'build_s3'
        SdkConfig = 'sdkconfig.s3'
        ChipTarget = 'esp32s3'
        Architecture = 'Xtensa'
    }
    'c6' = @{
        Name = 'ESP32-C6'
        BuildDir = 'build_c6'
        SdkConfig = 'sdkconfig.c6'
        ChipTarget = 'esp32c6'
        Architecture = 'RISC-V'
    }
}

$targetConfig = $config[$Target]

# Display header
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  KC-Device Build Script" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Target:       $($targetConfig.Name) ($($targetConfig.Architecture))" -ForegroundColor Yellow
Write-Host "  Build Dir:    $($targetConfig.BuildDir)" -ForegroundColor Yellow
Write-Host "  SDK Config:   $($targetConfig.SdkConfig)" -ForegroundColor Yellow
Write-Host "  Action:       $Action" -ForegroundColor Yellow
if ($Port) {
    Write-Host "  Port:         $Port" -ForegroundColor Yellow
}
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Build the idf.py command
$idfCmd = "idf.py"
$idfArgs = @(
    "-B", $targetConfig.BuildDir,
    "-D", "SDKCONFIG=$($targetConfig.SdkConfig)"
)

# Add port if specified
if ($Port) {
    $idfArgs += @("-p", $Port)
}

# Execute based on action
switch ($Action) {
    'build' {
        Write-Host "Building firmware for $($targetConfig.Name)..." -ForegroundColor Green
        & $idfCmd @idfArgs build
    }
    'flash' {
        Write-Host "Flashing firmware to $($targetConfig.Name)..." -ForegroundColor Green
        & $idfCmd @idfArgs flash
    }
    'monitor' {
        Write-Host "Starting serial monitor for $($targetConfig.Name)..." -ForegroundColor Green
        Write-Host "Press Ctrl+] to exit" -ForegroundColor Yellow
        & $idfCmd @idfArgs monitor
    }
    'clean' {
        Write-Host "Cleaning build directory for $($targetConfig.Name)..." -ForegroundColor Green
        & $idfCmd @idfArgs clean
    }
    'fullclean' {
        Write-Host "Performing full clean for $($targetConfig.Name)..." -ForegroundColor Green
        & $idfCmd @idfArgs fullclean
    }
    'menuconfig' {
        Write-Host "Opening menuconfig for $($targetConfig.Name)..." -ForegroundColor Green
        & $idfCmd @idfArgs menuconfig
    }
    'all' {
        Write-Host "Building and flashing firmware for $($targetConfig.Name)..." -ForegroundColor Green
        & $idfCmd @idfArgs build
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "Build successful! Flashing..." -ForegroundColor Green
            & $idfCmd @idfArgs flash
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "Flash successful! Starting monitor..." -ForegroundColor Green
                Write-Host "Press Ctrl+] to exit" -ForegroundColor Yellow
                & $idfCmd @idfArgs monitor
            }
        }
    }
}

# Check exit code
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "  ERROR: Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  SUCCESS: $Action completed for $($targetConfig.Name)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
