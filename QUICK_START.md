# Quick Start Guide - Setting Up AWS Credentials for Terraform

This guide helps you set up AWS credentials correctly to avoid common authentication errors like "SignatureDoesNotMatch" when using Terraform.

## Prerequisites

- AWS Account (Free tier is sufficient)
- AWS CLI installed
- Terraform installed

## Step-by-Step Setup

### Step 1: Install AWS CLI

**Windows:**
```powershell
# Download and install from: https://awscli.amazonaws.com/AWSCLIV2.msi
# Or use Chocolatey:
choco install awscli
```

**macOS:**
```bash
brew install awscli
```

**Linux (Ubuntu/Debian):**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Verify installation:
```bash
aws --version
```

### Step 2: Create AWS Access Keys

1. Log in to [AWS Console](https://console.aws.amazon.com/)
2. Navigate to **IAM** (Identity and Access Management)
3. Click **Users** in the left sidebar
4. Select your user (or create a new user)
5. Click the **Security credentials** tab
6. Under "Access keys", click **Create access key**
7. Choose **Command Line Interface (CLI)**
8. Click **Next**, then **Create access key**
9. **IMPORTANT:** Download or copy both:
   - Access Key ID (starts with `AKIA...`)
   - Secret Access Key (long string with special characters)

⚠️ **Security Note:** Save these credentials securely. AWS will not show the secret key again.

### Step 3: Configure AWS CLI

**Option A: Using AWS Configure (Recommended)**

```bash
aws configure
```

When prompted, enter:
- **AWS Access Key ID**: `AKIAIOSFODNN7EXAMPLE` (your actual key)
- **AWS Secret Access Key**: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` (your actual key)
- **Default region**: `us-east-1` (or your preferred region)
- **Default output format**: `json`

**Option B: Using Environment Variables**

**Linux/macOS:**
```bash
# Add to ~/.bashrc or ~/.zshrc for persistence
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"
```

**Windows PowerShell:**
```powershell
# Add to PowerShell profile for persistence
$env:AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
$env:AWS_DEFAULT_REGION="us-east-1"
```

### Step 4: Verify Your Setup

**Linux/macOS:**
```bash
bash verify-aws-setup.sh
```

**Windows PowerShell:**
```powershell
.\verify-aws-setup.ps1
```

You should see:
```
✅ All checks passed! You're ready to use Terraform with AWS.
```

### Step 5: Test Your Credentials

```bash
# Test AWS authentication
aws sts get-caller-identity

# Should return:
# {
#     "UserId": "AIDAIOSFODNN7EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-username"
# }
```

If this command succeeds, your credentials are correctly configured!

## Common Issues and Solutions

### Issue 1: "SignatureDoesNotMatch" Error

**Symptoms:**
```
Error: validating provider credentials: retrieving caller identity from STS: 
operation error STS: GetCallerIdentity, api error SignatureDoesNotMatch
```

**Most Common Cause:** Special characters in your secret key are not properly quoted.

**Solution:**
```bash
# ✅ ALWAYS use quotes for credentials
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# ❌ NEVER do this (without quotes)
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Issue 2: Spaces in Credentials

**Symptoms:** Authentication fails even though credentials look correct.

**Solution:**
```bash
# Check for spaces (you'll see them between the brackets)
echo "[$AWS_SECRET_ACCESS_KEY]"

# Remove spaces
export AWS_SECRET_ACCESS_KEY=$(echo "$AWS_SECRET_ACCESS_KEY" | tr -d '[:space:]')
```

### Issue 3: "NoCredentialProviders" Error

**Symptoms:**
```
Error: NoCredentialProviders: no valid providers in chain
```

**Solution:**
Either credentials are not set at all, or AWS CLI configuration is missing.
```bash
# Run AWS configure
aws configure

# Or set environment variables (see Step 3)
```

### Issue 4: Credentials Work with AWS CLI but Not Terraform

**Cause:** Terraform doesn't have access to the same credential source.

**Solution:**
```bash
# Ensure Terraform can find credentials
# Option 1: Use the same terminal session where you set environment variables

# Option 2: Explicitly test credential access
export AWS_PROFILE=default
terraform init
```

## Next Steps

Once your credentials are verified:

1. **Navigate to a lesson:**
   ```bash
   cd lessons/day03/
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan your infrastructure:**
   ```bash
   terraform plan
   ```

4. **Apply changes:**
   ```bash
   terraform apply
   ```

5. **Clean up resources:**
   ```bash
   terraform destroy
   ```

## Additional Resources

- 📖 [Complete Troubleshooting Guide](TROUBLESHOOTING.md)
- 🔧 [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/)
- 🏗️ [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- 🎓 [Course Lessons](lessons/)

## Security Best Practices

✅ **DO:**
- Use AWS CLI configuration (`aws configure`)
- Use IAM roles when running on EC2/ECS/Lambda
- Rotate access keys every 90 days
- Enable MFA on your AWS account
- Use separate AWS accounts for dev/staging/production

❌ **DON'T:**
- Commit credentials to version control
- Share credentials via email or chat
- Use root account access keys
- Hardcode credentials in Terraform files
- Reuse the same credentials across multiple environments

## Getting Help

If you're still experiencing issues after following this guide:

1. Run the verification script: `bash verify-aws-setup.sh`
2. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
3. Search existing issues in the repository
4. Create a new issue with:
   - Output of `aws --version`
   - Output of `terraform version`
   - Error message (without revealing actual credentials)
   - Steps you've already tried

---

**Happy Terraforming!** 🚀
