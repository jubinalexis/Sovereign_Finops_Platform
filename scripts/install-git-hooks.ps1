# Pre-commit hook installation script for Windows
# Run this once to enable automatic secret scanning

$ErrorActionPreference = "Stop"

Write-Host "=== Installing Git Pre-Commit Hook ===" -ForegroundColor Cyan

# Check  if .git directory exists
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in a Git repository!" -ForegroundColor Red
    Write-Host "Run this script from the repository root." -ForegroundColor Yellow
    exit 1
}

# Create .git/hooks directory if it doesn't exist
if (-not (Test-Path ".git/hooks")) {
    New-Item -ItemType Directory -Path ".git/hooks" -Force | Out-Null
}

# Copy pre-commit hook
$source = ".githooks/pre-commit"
$destination = ".git/hooks/pre-commit"

if (Test-Path $source) {
    Copy-Item $source $destination -Force
    Write-Host "✅ Pre-commit hook installed!" -ForegroundColor Green
}
else {
    Write-Host "❌ Error: .githooks/pre-commit not found!" -ForegroundColor Red
    exit 1
}

# Check if gitleaks is installed
Write-Host ""
Write-Host "Checking for gitleaks..." -ForegroundColor Cyan
$gitleaksInstalled = Get-Command gitleaks -ErrorAction SilentlyContinue

if ($gitleaksInstalled) {
    Write-Host "✅ Gitleaks is installed" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Gitleaks is NOT installed" -ForegroundColor Yellow
    Write-Host "The pre-commit hook will still run basic checks, but won't use gitleaks." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To install gitleaks:" -ForegroundColor Cyan
    Write-Host "  winget install gitleaks" -ForegroundColor White
    Write-Host "  OR download from: https://github.com/gitleaks/gitleaks/releases" -ForegroundColor White
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Green
Write-Host "The pre-commit hook will now run automatically before each commit." -ForegroundColor Green
Write-Host ""
Write-Host "Features enabled:" -ForegroundColor Cyan
Write-Host "  ✓ Secret scanning (if gitleaks is installed)" -ForegroundColor White
Write-Host "  ✓ Pattern-based secret detection" -ForegroundColor White
Write-Host "  ✓ Large file detection (>10MB)" -ForegroundColor White
Write-Host "  ✓ AWS credentials check" -ForegroundColor White
Write-Host ""
Write-Host "To bypass the hook (NOT RECOMMENDED):" -ForegroundColor Yellow
Write-Host "  git commit --no-verify" -ForegroundColor White
