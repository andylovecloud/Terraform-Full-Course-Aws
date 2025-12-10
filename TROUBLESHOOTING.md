# Troubleshooting Guide - AWS and Terraform Issues

## Common AWS Authentication Errors

### Error: SignatureDoesNotMatch - STS GetCallerIdentity Failure

#### Full Error Message
```
Error: validating provider credentials: retrieving caller identity from STS: operation error STS: GetCallerIdentity, https response error StatusCode: 403, RequestID: xxx, api error SignatureDoesNotMatch: The request signature we calculated does not match the signature you provided. Check your AWS Secret Access Key and signing method. Consult the service documentation for details.
```

#### What This Error Means
This error occurs when Terraform attempts to validate your AWS credentials by calling the AWS Security Token Service (STS) `GetCallerIdentity` API, but the signature calculation fails. This is typically a credential configuration issue, not a permissions problem.

#### Root Causes and Solutions

##### 1. Special Characters in AWS Secret Access Key

**Problem:** AWS Secret Access Keys can contain special characters like `+`, `/`, `=` which may be misinterpreted by shells or configuration files.

**Solution:**
Always quote your AWS credentials when setting them:

```bash
# ✅ CORRECT - Using quotes
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# ❌ INCORRECT - Missing quotes (special characters may be misinterpreted)
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

##### 2. Leading or Trailing Spaces in Credentials

**Problem:** Accidentally copying credentials with extra spaces.

**Solution:**
Verify credentials don't have spaces:

```bash
# Check for spaces in your credentials
echo "[$AWS_ACCESS_KEY_ID]"
echo "[$AWS_SECRET_ACCESS_KEY]"

# If you see spaces, trim them:
export AWS_ACCESS_KEY_ID=$(echo "$AWS_ACCESS_KEY_ID" | tr -d '[:space:]')
export AWS_SECRET_ACCESS_KEY=$(echo "$AWS_SECRET_ACCESS_KEY" | tr -d '[:space:]')
```

##### 3. Incorrect AWS CLI Configuration

**Problem:** Credentials in `~/.aws/credentials` file have formatting issues.

**Solution:**
Verify your credentials file format:

```bash
# Check the credentials file
cat ~/.aws/credentials

# Should look like:
# [default]
# aws_access_key_id = AKIAIOSFODNN7EXAMPLE
# aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Fix configuration:**
```bash
# Reconfigure AWS CLI
aws configure
# Enter your credentials when prompted
```

##### 4. Using Wrong Credentials

**Problem:** Using old, rotated, or invalid credentials.

**Solution:**
Verify your credentials are active:

```bash
# Test credentials directly with AWS CLI
aws sts get-caller-identity

# Should return:
# {
#     "UserId": "AIDAIOSFODNN7EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/username"
# }
```

If this fails, your credentials need to be regenerated in the AWS IAM Console.

##### 5. Environment Variable Conflicts

**Problem:** Multiple credential sources conflicting (environment variables, credentials file, IAM role).

**Solution:**
Check all credential sources:

```bash
# Check environment variables
env | grep AWS

# Temporarily unset environment variables to use credentials file
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_PROFILE

# Or use a specific profile
export AWS_PROFILE=default
```

##### 6. System Clock Skew

**Problem:** Your system clock is significantly out of sync with AWS servers (more than 5 minutes).

**Solution:**
Sync your system clock:

**Linux/macOS:**
```bash
# Check current time
date

# Sync time (requires sudo)
sudo ntpdate -s time.nist.gov
# Or on systemd systems:
sudo timedatectl set-ntp true
```

**Windows:**
```powershell
# Sync time
w32tm /resync
```

##### 7. Regional Endpoint Issues

**Problem:** Using wrong AWS region or region-specific endpoints.

**Solution:**
Verify region configuration:

```bash
# Check configured region
aws configure get region

# Set correct region
export AWS_DEFAULT_REGION=us-east-1

# Or in Terraform provider block
provider "aws" {
  region = "us-east-1"
}
```

#### Comprehensive Verification Steps

Before running Terraform, verify your AWS setup:

```bash
#!/bin/bash
# AWS Credential Verification Script

echo "=== AWS Credential Verification ==="
echo ""

echo "1. Checking AWS CLI installation..."
if command -v aws &> /dev/null; then
    echo "✅ AWS CLI is installed: $(aws --version)"
else
    echo "❌ AWS CLI is not installed"
    exit 1
fi

echo ""
echo "2. Checking environment variables..."
if [ -n "$AWS_ACCESS_KEY_ID" ]; then
    echo "✅ AWS_ACCESS_KEY_ID is set: ${AWS_ACCESS_KEY_ID:0:10}..."
else
    echo "⚠️  AWS_ACCESS_KEY_ID not set in environment"
fi

if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "✅ AWS_SECRET_ACCESS_KEY is set: ${AWS_SECRET_ACCESS_KEY:0:5}..."
else
    echo "⚠️  AWS_SECRET_ACCESS_KEY not set in environment"
fi

echo ""
echo "3. Testing AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS credentials are valid"
    aws sts get-caller-identity
else
    echo "❌ AWS credential validation failed"
    echo "Please check your credentials"
    exit 1
fi

echo ""
echo "4. Checking system time..."
current_time=$(date +%s)
echo "Current system time: $(date)"

echo ""
echo "5. Checking AWS region..."
region=$(aws configure get region)
if [ -n "$region" ]; then
    echo "✅ AWS region is set: $region"
else
    echo "⚠️  AWS region not configured"
    echo "Set it with: aws configure set region us-east-1"
fi

echo ""
echo "=== Verification Complete ==="
```

Save this as `verify-aws-setup.sh` and run:
```bash
chmod +x verify-aws-setup.sh
./verify-aws-setup.sh
```

#### Best Practices for AWS Credentials

1. **Use AWS CLI Configuration** (Recommended for local development)
   ```bash
   aws configure
   ```
   This stores credentials securely in `~/.aws/credentials`

2. **Use Environment Variables** (For CI/CD pipelines)
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

3. **Use IAM Roles** (Best for EC2/ECS/Lambda)
   - No credentials needed in code
   - Automatically rotated by AWS
   - Most secure option

4. **Never Hardcode Credentials**
   ```terraform
   # ❌ NEVER DO THIS
   provider "aws" {
     access_key = "AKIAIOSFODNN7EXAMPLE"
     secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
   }
   
   # ✅ DO THIS INSTEAD
   provider "aws" {
     region = "us-east-1"
     # Credentials loaded from environment or credentials file
   }
   ```

#### Still Having Issues?

If you've tried all the above solutions and still encounter the error:

1. **Generate New Credentials**
   - Go to AWS IAM Console
   - Navigate to your user
   - Security Credentials tab
   - Create new access key
   - Delete old access key after verifying new one works

2. **Check IAM Permissions**
   - Ensure your IAM user/role has necessary permissions
   - At minimum, you need permission to call `sts:GetCallerIdentity`

3. **Test with AWS CLI First**
   - Always verify credentials work with AWS CLI before using Terraform
   - Run: `aws sts get-caller-identity`

4. **Check AWS Service Health**
   - Visit: https://health.aws.amazon.com/health/status
   - Verify STS service is operational in your region

## Additional Common Errors

### Error: "NoCredentialProviders: no valid providers in chain"

**Cause:** No AWS credentials found.

**Solution:**
```bash
# Configure AWS credentials
aws configure
```

### Error: "ExpiredToken: The security token included in the request is expired"

**Cause:** Using temporary credentials (session token) that have expired.

**Solution:**
```bash
# Re-authenticate and get new temporary credentials
# If using AWS SSO:
aws sso login

# If using assume role:
# Generate new temporary credentials
```

### Error: "Access Denied" but credentials are valid

**Cause:** IAM permissions issue.

**Solution:**
```bash
# Check what identity you're using
aws sts get-caller-identity

# Verify IAM policy allows required actions
# Contact your AWS administrator
```

## Terraform-Specific Tips

### Initialize Terraform with Proper Credentials
```bash
# Verify AWS credentials first
aws sts get-caller-identity

# Then initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan with detailed logging if needed
TF_LOG=DEBUG terraform plan
```

### Debug Terraform AWS Provider Issues
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log

# Run Terraform
terraform plan

# Review log file for detailed error messages
cat terraform-debug.log | grep -i "error\|signature"
```

## Getting Help

If this guide doesn't resolve your issue:

1. Check Terraform AWS Provider documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
2. Review AWS CLI documentation: https://docs.aws.amazon.com/cli/latest/userguide/
3. Search GitHub Issues: https://github.com/hashicorp/terraform-provider-aws/issues
4. AWS Support: https://console.aws.amazon.com/support/

## Security Reminders

⚠️ **Important Security Practices:**
- Never commit AWS credentials to version control
- Rotate access keys regularly (every 90 days)
- Use IAM roles when possible instead of long-term credentials
- Enable MFA for your AWS account
- Follow the principle of least privilege for IAM permissions
- Use AWS Secrets Manager or AWS Systems Manager Parameter Store for application secrets
