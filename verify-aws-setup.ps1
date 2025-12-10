# AWS Credential Verification Script (PowerShell)
# This script helps diagnose common AWS credential and authentication issues
# Run this before executing Terraform commands to ensure proper setup

$ErrorActionPreference = "Continue"

# Icons
$CHECK = [char]0x2705
$CROSS = [char]0x274C  
$WARNING = [char]0x26A0
$INFO = [char]0x2139

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║   AWS Credential Verification Script              ║" -ForegroundColor Blue
Write-Host "║   Diagnose authentication issues before Terraform  ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Check 1: AWS CLI Installation
Write-Host "[1/7] Checking AWS CLI installation..." -ForegroundColor Blue
try {
    $awsVersion = aws --version 2>&1
    Write-Host "$CHECK AWS CLI is installed" -ForegroundColor Green
    Write-Host "    Version: $awsVersion" -ForegroundColor Gray
} catch {
    Write-Host "$CROSS AWS CLI is not installed" -ForegroundColor Red
    Write-Host "$WARNING Please install AWS CLI: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Check 2: Environment Variables
Write-Host "[2/7] Checking environment variables..." -ForegroundColor Blue
$envVarSet = $false

if ($env:AWS_ACCESS_KEY_ID) {
    Write-Host "$CHECK AWS_ACCESS_KEY_ID is set" -ForegroundColor Green
    $keyPreview = $env:AWS_ACCESS_KEY_ID.Substring(0, [Math]::Min(12, $env:AWS_ACCESS_KEY_ID.Length))
    Write-Host "    Value: $keyPreview... (showing first 12 chars)" -ForegroundColor Gray
    
    # Check for spaces
    if ($env:AWS_ACCESS_KEY_ID -match '\s') {
        Write-Host "$CROSS WARNING: AWS_ACCESS_KEY_ID contains spaces!" -ForegroundColor Red
        Write-Host "    This will cause authentication failures." -ForegroundColor Yellow
        Write-Host "    Fix: `$env:AWS_ACCESS_KEY_ID = `$env:AWS_ACCESS_KEY_ID.Trim()" -ForegroundColor Yellow
    }
    $envVarSet = $true
} else {
    Write-Host "$WARNING AWS_ACCESS_KEY_ID not set in environment" -ForegroundColor Yellow
}

if ($env:AWS_SECRET_ACCESS_KEY) {
    Write-Host "$CHECK AWS_SECRET_ACCESS_KEY is set" -ForegroundColor Green
    $secretPreview = $env:AWS_SECRET_ACCESS_KEY.Substring(0, [Math]::Min(5, $env:AWS_SECRET_ACCESS_KEY.Length))
    Write-Host "    Value: $secretPreview... (showing first 5 chars)" -ForegroundColor Gray
    
    # Check for spaces
    if ($env:AWS_SECRET_ACCESS_KEY -match '\s') {
        Write-Host "$CROSS WARNING: AWS_SECRET_ACCESS_KEY contains spaces!" -ForegroundColor Red
        Write-Host "    This will cause authentication failures." -ForegroundColor Yellow
        Write-Host "    Fix: `$env:AWS_SECRET_ACCESS_KEY = `$env:AWS_SECRET_ACCESS_KEY.Trim()" -ForegroundColor Yellow
    }
    $envVarSet = $true
} else {
    Write-Host "$WARNING AWS_SECRET_ACCESS_KEY not set in environment" -ForegroundColor Yellow
}

if ($env:AWS_SESSION_TOKEN) {
    Write-Host "$CHECK AWS_SESSION_TOKEN is set (temporary credentials)" -ForegroundColor Green
    $envVarSet = $true
}

if ($env:AWS_PROFILE) {
    Write-Host "$CHECK AWS_PROFILE is set: $($env:AWS_PROFILE)" -ForegroundColor Green
} else {
    Write-Host "$INFO AWS_PROFILE not set (will use 'default' profile)" -ForegroundColor Cyan
}

if (-not $envVarSet) {
    Write-Host "$INFO No AWS environment variables set" -ForegroundColor Cyan
    Write-Host "    Credentials will be loaded from ~/.aws/credentials" -ForegroundColor Gray
}
Write-Host ""

# Check 3: AWS Credentials File
Write-Host "[3/7] Checking AWS credentials file..." -ForegroundColor Blue
$credentialsPath = "$env:USERPROFILE\.aws\credentials"
if (Test-Path $credentialsPath) {
    Write-Host "$CHECK Credentials file exists: $credentialsPath" -ForegroundColor Green
    
    $credContent = Get-Content $credentialsPath -Raw
    if ($credContent -match '\[default\]') {
        Write-Host "$CHECK Default profile found" -ForegroundColor Green
    } else {
        Write-Host "$WARNING No [default] profile in credentials file" -ForegroundColor Yellow
    }
    
    # List available profiles
    $profiles = Select-String -Path $credentialsPath -Pattern '^\[' | ForEach-Object { $_.Line -replace '[\[\]]', '' }
    if ($profiles) {
        Write-Host "    Available profiles: $($profiles -join ', ')" -ForegroundColor Gray
    }
} else {
    Write-Host "$WARNING Credentials file not found: $credentialsPath" -ForegroundColor Yellow
    Write-Host "$INFO Run 'aws configure' to create it" -ForegroundColor Cyan
}
Write-Host ""

# Check 4: AWS Config File
Write-Host "[4/7] Checking AWS config file..." -ForegroundColor Blue
$configPath = "$env:USERPROFILE\.aws\config"
if (Test-Path $configPath) {
    Write-Host "$CHECK Config file exists: $configPath" -ForegroundColor Green
    
    try {
        $region = aws configure get region 2>$null
        if ($region) {
            Write-Host "$CHECK Default region configured: $region" -ForegroundColor Green
        } else {
            Write-Host "$WARNING No default region configured" -ForegroundColor Yellow
            Write-Host "    Set with: aws configure set region us-east-1" -ForegroundColor Gray
        }
    } catch {
        Write-Host "$WARNING Could not retrieve region" -ForegroundColor Yellow
    }
} else {
    Write-Host "$WARNING Config file not found: $configPath" -ForegroundColor Yellow
}
Write-Host ""

# Check 5: Test AWS Credentials
Write-Host "[5/7] Testing AWS credentials with STS GetCallerIdentity..." -ForegroundColor Blue
$stsFailed = $false
$stsOutput = ""
try {
    $stsOutput = aws sts get-caller-identity 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        $stsFailed = $true
    }
} catch {
    $stsFailed = $true
}

if ($stsFailed) {
    Write-Host "$CROSS AWS credential validation FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error output:" -ForegroundColor Red
    Write-Host $stsOutput -ForegroundColor Gray
    Write-Host ""
    Write-Host "Common causes:" -ForegroundColor Yellow
    Write-Host "  1. Invalid or expired credentials"
    Write-Host "  2. Special characters in secret key not properly quoted"
    Write-Host "  3. Spaces in credentials"
    Write-Host "  4. System clock skew (time difference > 5 minutes)"
    Write-Host "  5. Incorrect AWS region or endpoint"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Verify credentials: aws configure"
    Write-Host '  2. Check for spaces: Write-Host "[$env:AWS_SECRET_ACCESS_KEY]"'
    Write-Host "  3. Regenerate credentials in AWS IAM Console"
    Write-Host "  4. See TROUBLESHOOTING.md for detailed solutions"
    Write-Host ""
    exit 1
} else {
    Write-Host "$CHECK AWS credentials are VALID!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Account Details:" -ForegroundColor Green
    try {
        $stsJson = $stsOutput | ConvertFrom-Json
        Write-Host "  UserId:  $($stsJson.UserId)" -ForegroundColor Gray
        Write-Host "  Account: $($stsJson.Account)" -ForegroundColor Gray
        Write-Host "  Arn:     $($stsJson.Arn)" -ForegroundColor Gray
    } catch {
        Write-Host $stsOutput -ForegroundColor Gray
    }
}
Write-Host ""

# Check 6: System Time
Write-Host "[6/7] Checking system time for clock skew..." -ForegroundColor Blue
$currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
Write-Host "$CHECK Current system time: $currentTime" -ForegroundColor Green

# Try to detect clock skew from error messages
if ($stsOutput -match "RequestTimeTooSkewed") {
    Write-Host "$CROSS System clock is out of sync with AWS servers!" -ForegroundColor Red
    Write-Host "    Fix: w32tm /resync (Run as Administrator)" -ForegroundColor Yellow
} else {
    Write-Host "$CHECK System time appears to be in sync" -ForegroundColor Green
}
Write-Host ""

# Check 7: Terraform Check
Write-Host "[7/7] Checking Terraform installation..." -ForegroundColor Blue
try {
    $terraformVersion = terraform version 2>&1 | Select-Object -First 1
    Write-Host "$CHECK Terraform is installed" -ForegroundColor Green
    Write-Host "    Version: $terraformVersion" -ForegroundColor Gray
} catch {
    Write-Host "$WARNING Terraform is not installed" -ForegroundColor Yellow
    Write-Host "$INFO Install from: https://www.terraform.io/downloads" -ForegroundColor Cyan
}
Write-Host ""

# Summary
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║                  VERIFICATION SUMMARY              ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

if (-not $stsFailed) {
    Write-Host "$CHECK All checks passed! You're ready to use Terraform with AWS." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host "  1. Navigate to a lesson directory (e.g., cd lessons\day03\)"
    Write-Host "  2. Initialize Terraform: terraform init"
    Write-Host "  3. Plan your infrastructure: terraform plan"
    Write-Host "  4. Apply changes: terraform apply"
    Write-Host ""
    Write-Host "Happy Terraforming! " -NoNewline -ForegroundColor Green
    Write-Host [char]0x1F680 -ForegroundColor Green
} else {
    Write-Host "$CROSS Credential validation failed." -ForegroundColor Red
    Write-Host "Please review the error messages above and fix the issues." -ForegroundColor Yellow
    Write-Host "For detailed troubleshooting, see: TROUBLESHOOTING.md" -ForegroundColor Yellow
    exit 1
}
