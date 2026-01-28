# Pre-Deployment Security Validation Script
# Validates configuration before deploying to production

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"
$ValidationErrors = @()
$ValidationWarnings = @()

Write-Host "=== ArgoCD Pre-Deployment Security Validation ===" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

# Function to add error
function Add-ValidationError {
    param([string]$Message)
    $script:ValidationErrors += $Message
    Write-Host "❌ ERROR: $Message" -ForegroundColor Red
}

# Function to add warning
function Add-ValidationWarning {
    param([string]$Message)
    $script:ValidationWarnings += $Message
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Yellow
}

# Function to add success
function Add-ValidationSuccess {
    param([string]$Message)
    Write-Host "✅ PASS: $Message" -ForegroundColor Green
}

# ========================================
# 1. Check ArgoCD Values File
# ========================================

Write-Host "1. Validating ArgoCD configuration..." -ForegroundColor Cyan

$valuesFile = if ($Environment -eq "prod") { "argocd-values-prod.yaml" } else { "argocd-values-dev.yaml" }

if (-not (Test-Path $valuesFile)) {
    Add-ValidationError "ArgoCD values file not found: $valuesFile"
}
else {
    Add-ValidationSuccess "ArgoCD values file found: $valuesFile"
    
    $content = Get-Content $valuesFile -Raw
    
    # Check for insecure configurations in PRODUCTION
    if ($Environment -eq "prod") {
        if ($content -match "insecure:\s*true") {
            Add-ValidationError "PRODUCTION: insecure: true is NOT allowed! TLS must be enabled."
        }
        else {
            Add-ValidationSuccess "TLS is enabled (insecure: false or not set)"
        }
        
        if ($content -match "anonymous\.enabled.*true" -or $content -match "policy\.default:\s*role:admin") {
            Add-ValidationError "PRODUCTION: Anonymous admin access is NOT allowed!"
        }
        else {
            Add-ValidationSuccess "Anonymous access is disabled"
        }
        
        if ($content -notmatch "oidc\.config" -and $content -notmatch "dex\.config") {
            Add-ValidationWarning "SSO (OIDC/SAML) configuration not detected. Consider enabling for production."
        }
        else {
            Add-ValidationSuccess "SSO configuration detected"
        }
        
        if ($content -match "replicaCount:\s*1" -or $content -notmatch "replicaCount") {
            Add-ValidationWarning "Single replica detected. Consider HA with replicas: 3 for production."
        }
        else {
            Add-ValidationSuccess "Multiple replicas configured for HA"
        }
    }
    
    # Check for DEV environment warnings
    if ($Environment -eq "dev") {
        if ($content -match "insecure:\s*true") {
            Add-ValidationWarning "DEV: insecure: true detected (OK for local dev, NEVER use in prod)"
        }
        
        if ($content -match "anonymous\.enabled.*true") {
            Add-ValidationWarning "DEV: Anonymous access enabled (OK for local dev, NEVER use in prod)"
        }
    }
}

# ========================================
# 2. Secret Scanning
# ========================================

Write-Host ""
Write-Host "2. Scanning for committed secrets..." -ForegroundColor Cyan

# Check if gitleaks is installed
$gitleaksInstalled = Get-Command gitleaks -ErrorAction SilentlyContinue

if ($gitleaksInstalled) {
    try {
        $result = gitleaks detect --source . --no-git 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-ValidationSuccess "No secrets found by gitleaks"
        }
        else {
            Add-ValidationError "Gitleaks found potential secrets! Run 'gitleaks detect' for details"
        }
    }
    catch {
        Add-ValidationWarning "Gitleaks scan failed: $_"
    }
}
else {
    Add-ValidationWarning "Gitleaks not installed. Install with: 'winget install gitleaks' or 'brew install gitleaks'"
}

# Simple regex-based secret detection
$suspiciousPatterns = @(
    @{Name = "AWS Key"; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{Name = "Generic API Key"; Pattern = 'api[_-]?key["\s:=]+[a-zA-Z0-9]{32,}' },
    @{Name = "Password in clear"; Pattern = 'password["\s:=]+[^$\{][a-zA-Z0-9!@#$%^&*]{8,}' },
    @{Name = "Private Key"; Pattern = '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' }
)

$files = Get-ChildItem -Recurse -File -Include *.yaml, *.yml, *.json, *.sh, *.ps1 -Exclude node_modules, *.git*

foreach ($file in $files) {
    $fileContent = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($pattern in $suspiciousPatterns) {
        if ($fileContent -match $pattern.Pattern) {
            Add-ValidationWarning "$($pattern.Name) pattern detected in: $($file.Name)"
        }
    }
}

# ========================================
# 3. RBAC Configuration Check
# ========================================

Write-Host ""
Write-Host "3. Validating RBAC Configuration..." -ForegroundColor Cyan

if ($Environment -eq "prod") {
    if ($content -match "policy\.csv") {
        Add-ValidationSuccess "RBAC policy.csv is configured"
        
        # Check if least-privilege is applied
        if ($content -match "policy\.default:\s*role:admin") {
            Add-ValidationError "Default policy grants admin role - this is too permissive!"
        }
        elseif ($content -match 'policy\.default:\s*""') {
            Add-ValidationSuccess "Default policy is deny-all (secure)"
        }
    }
    else {
        Add-ValidationWarning "No RBAC policies found. All authenticated users may have full access."
    }
}

# ========================================
# 4. Check for Hardcoded Credentials
# ========================================

Write-Host ""
Write-Host "4. Checking for hardcoded credentials..." -ForegroundColor Cyan

$credentialPaths = @(
    "argocd-values-*.yaml",
    "infra/terraform/*.tf",
    "scripts/*.sh",
    "scripts/*.ps1"
)

$hardcodedCredsFound = $false

foreach ($path in $credentialPaths) {
    $matchingFiles = Get-ChildItem $path -ErrorAction SilentlyContinue
    foreach ($file in $matchingFiles) {
        $fileContent = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        # Look for suspicious patterns
        if ($fileContent -match 'clientSecret:\s*["\']?[a-zA-Z0-9] { 20, }') {
            Add-ValidationError "Hardcoded clientSecret detected in: $($file.Name)"
            $hardcodedCredsFound = $true
        }
        
        if ($fileContent -match 'token:\s*["\']?[a-zA-Z0-9]{20,}') {
            Add-ValidationWarning "Potential hardcoded token in: $($file.Name)"
        }
    }
}

if (-not $hardcodedCredsFound) {
    Add-ValidationSuccess "No hardcoded credentials detected"
}

# ========================================
# 5. Network Security
# ========================================

Write-Host ""
Write-Host "5. Checking network security configuration..." -ForegroundColor Cyan

if ($Environment -eq "prod") {
    if ($content -match "networkPolicy:\s*enabled:\s*true") {
        Add-ValidationSuccess "NetworkPolicies are enabled"
    } else {
        Add-ValidationWarning "NetworkPolicies not enabled. Consider enabling for network segmentation."
    }
    
    if ($content -match "ingress:\s*enabled:\s*true") {
        if ($content -match "force-ssl-redirect") {
            Add-ValidationSuccess "HTTPS redirect is configured"
        } else {
            Add-ValidationWarning "HTTPS redirect not detected. Consider adding nginx.ingress.kubernetes.io/force-ssl-redirect"
        }
    }
}

# ========================================
# 6. Resource Limits
# ========================================

Write-Host ""
Write-Host "6. Validating resource limits..." -ForegroundColor Cyan

if ($content -match "resources:\s*limits:") {
    Add-ValidationSuccess "Resource limits are configured"
} else {
    Add-ValidationWarning "No resource limits configured. This can lead to resource exhaustion."
}

# ========================================
# 7. Security Context Check
# ========================================

Write-Host ""
Write-Host "7. Checking pod security context..." -ForegroundColor Cyan

if ($Environment -eq "prod") {
    if ($content -match "runAsNonRoot:\s*true") {
        Add-ValidationSuccess "Pods configured to run as non-root"
    } else {
        Add-ValidationWarning "runAsNonRoot not detected. Pods may run as root."
    }
    
    if ($content -match "readOnlyRootFilesystem:\s*true") {
        Add-ValidationSuccess "Read-only root filesystem configured"
    } else {
        Add-ValidationWarning "Read-only root filesystem not configured"
    }
}

# ========================================
# SUMMARY
# ========================================

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "Errors: $($ValidationErrors.Count)" -ForegroundColor $(if ($ValidationErrors.Count -gt 0) { "Red" } else { "Green" })
Write-Host "Warnings: $($ValidationWarnings.Count)" -ForegroundColor Yellow

if ($ValidationErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ VALIDATION FAILED - Fix the following errors:" -ForegroundColor Red
    foreach ($error in $ValidationErrors) {
        Write-Host "   - $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Deployment BLOCKED for $Environment environment" -ForegroundColor Red
    exit 1
}

if ($ValidationWarnings.Count -gt 0 -and $Environment -eq "prod") {
    Write-Host ""
    Write-Host "⚠️  WARNINGS detected (review recommended):" -ForegroundColor Yellow
    foreach ($warning in $ValidationWarnings) {
        Write-Host "   - $warning" -ForegroundColor Yellow
    }
    
    Write-Host ""
    $continue = Read-Host "Continue with deployment to PRODUCTION? (yes/no)"
    if ($continue -ne "yes") {
        Write-Host "Deployment cancelled by user" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "✅ VALIDATION PASSED" -ForegroundColor Green
Write-Host "Safe to deploy to $Environment environment" -ForegroundColor Green
exit 0
