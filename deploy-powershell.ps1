# --- GENERIC DEPLOYMENT SCRIPT (PowerShell) ---
Write-Host "--- Starting Deployment Script... ---"

# --- Configuration ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
if (-not (Test-Path $ConfigPath)) {
    Write-Host "Configuration file not found at '$ConfigPath'." -ForegroundColor Red
    Write-Host "Please copy 'config.example.json' to 'config.json' and fill in your details." -ForegroundColor Red
    exit 1
}

$Config = Get-Content $ConfigPath | Out-String | ConvertFrom-Json
$PiUser = $Config.piUser
$PiIpAddress = $Config.piIpAddress
$TempDirOnPi = $Config.tempDirOnPi
$FinalDirOnPi = $Config.finalDirOnPi

# Optional config with defaults
$BuildCommand = if ($Config.buildCommand) { $Config.buildCommand } else { "npm run build" }
$BuildDir = if ($Config.buildDir) { $Config.buildDir } else { "build" }

if (-not ($PiUser -and $PiIpAddress -and $TempDirOnPi -and $FinalDirOnPi)) {
    Write-Host "One or more configuration values are missing in '$ConfigPath'." -ForegroundColor Red
    exit 1
}

# --- Static Configuration ---
# Get project root (parent of deploy folder)
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$SourceDir = Join-Path $ProjectRoot $BuildDir
$TarFile = "build.tar.gz"

# --- Script ---
# Change to project root directory
Push-Location $ProjectRoot

# Step 1: Build the application for production
Write-Host ""
Write-Host "Step 1: Building the application..." -ForegroundColor Green
Invoke-Expression $BuildCommand
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Aborting deployment." -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 2: Compress build files
Write-Host ""
Write-Host "Step 2: Compressing build files..." -ForegroundColor Green
tar -czf $TarFile -C $SourceDir .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Compression failed! Aborting deployment." -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 3: Transfer compressed archive to the remote server
Write-Host ""
Write-Host "Step 3: Transferring compressed archive to remote server..." -ForegroundColor Green
scp $TarFile "${PiUser}@${PiIpAddress}:~/$TarFile"
if ($LASTEXITCODE -ne 0) {
    Write-Host "SCP transfer failed! Aborting deployment." -ForegroundColor Red
    Remove-Item $TarFile -ErrorAction SilentlyContinue
    Pop-Location
    exit 1
}

# Step 4: Deploy files on the remote server via SSH
Write-Host ""
Write-Host "Step 4: Deploying files on the remote server..." -ForegroundColor Green
$SshCommand = "mkdir -p $TempDirOnPi && tar -xzf ~/$TarFile -C $TempDirOnPi && sudo rm -rf $FinalDirOnPi/* && sudo mv $TempDirOnPi/* $FinalDirOnPi/ && sudo chown -R www-data:www-data $FinalDirOnPi && sudo chmod -R 755 $FinalDirOnPi && rm -rf $TempDirOnPi ~/$TarFile"
ssh "${PiUser}@${PiIpAddress}" $SshCommand
if ($LASTEXITCODE -ne 0) {
    Write-Host "SSH deployment commands failed! Please check permissions on the remote server." -ForegroundColor Red
    Remove-Item $TarFile -ErrorAction SilentlyContinue
    Pop-Location
    exit 1
}

# Step 5: Cleanup local tar file
Remove-Item $TarFile -ErrorAction SilentlyContinue

# Restore original directory
Pop-Location

# Step 6: Completion
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host " Deployment complete! " -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host ""
