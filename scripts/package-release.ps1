$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$staging = Join-Path $workspace "dist\staging\release"

Write-Host "Creating clean staging directory: $staging"
if (Test-Path $staging) {
    Remove-Item -Recurse -Force $staging
}
New-Item -ItemType Directory -Path $staging | Out-Null
New-Item -ItemType Directory -Path (Join-Path $staging "config") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $staging "config\profiles") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $staging "layer") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $staging "scripts") | Out-Null

# Copy root documents
Copy-Item (Join-Path $workspace "README.md") $staging
Copy-Item (Join-Path $workspace "QUICKSTART.md") $staging
Copy-Item (Join-Path $workspace "LICENSE") $staging

# Copy install script to root and scripts/
Copy-Item (Join-Path $workspace "scripts\install.sh") (Join-Path $staging "install.sh")
Copy-Item (Join-Path $workspace "scripts\install.sh") (Join-Path $staging "scripts\install.sh")

# Copy scripts
Copy-Item (Join-Path $workspace "scripts\lsfg-frame") (Join-Path $staging "scripts\lsfg-frame")
Copy-Item (Join-Path $workspace "scripts\verify-env.sh") (Join-Path $staging "scripts\verify-env.sh")
Copy-Item (Join-Path $workspace "scripts\smoke-test-layer.sh") (Join-Path $staging "scripts\smoke-test-layer.sh")

# Copy layer manifest
Copy-Item (Join-Path $workspace "layer\VkLayer_LSFGVK_frame_generation.json") (Join-Path $staging "layer\VkLayer_LSFGVK_frame_generation.json")

# Copy configs
Copy-Item (Join-Path $workspace "config\config.default.toml") (Join-Path $staging "config\config.default.toml")
Copy-Item (Join-Path $workspace "config\profiles\*.toml") (Join-Path $staging "config\profiles\")

# Normalize all text and shell scripts to Unix LF line endings
Get-ChildItem -Path $staging -Recurse -File | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName)
    $textLF = $text.Replace("`r`n", "`n")
    [IO.File]::WriteAllText($_.FullName, $textLF, (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "Staging prepared with Unix LF line endings."

# Package into zip files
$zipInstaller = Join-Path $workspace "steam-frame-lsfg-installer.zip"
$zipRelease = Join-Path $workspace "steam-frame-lsfg-v1.0.0.zip"

if (Test-Path $zipInstaller) { Remove-Item -Force $zipInstaller }
if (Test-Path $zipRelease) { Remove-Item -Force $zipRelease }

tar -a -c -f $zipInstaller -C $staging .
tar -a -c -f $zipRelease -C $staging .

Write-Host "Generated archives successfully:"
Get-Item $zipInstaller, $zipRelease | Select-Object Name, Length, LastWriteTime
