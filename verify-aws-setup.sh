#!/bin/bash

# AWS Credential Verification Script
# This script helps diagnose common AWS credential and authentication issues
# Run this before executing Terraform commands to ensure proper setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Icons
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AWS Credential Verification Script              ║${NC}"
echo -e "${BLUE}║   Diagnose authentication issues before Terraform  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Check 1: AWS CLI Installation
echo -e "${BLUE}[1/7] Checking AWS CLI installation...${NC}"
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1)
    echo -e "${GREEN}${CHECK} AWS CLI is installed${NC}"
    echo -e "    Version: ${AWS_VERSION}"
else
    echo -e "${RED}${CROSS} AWS CLI is not installed${NC}"
    echo -e "${YELLOW}${WARNING} Please install AWS CLI: https://aws.amazon.com/cli/${NC}"
    exit 1
fi
echo ""

# Check 2: Environment Variables
echo -e "${BLUE}[2/7] Checking environment variables...${NC}"
ENV_VAR_SET=false

if [ -n "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${GREEN}${CHECK} AWS_ACCESS_KEY_ID is set${NC}"
    echo -e "    Value: ${AWS_ACCESS_KEY_ID:0:12}... (showing first 12 chars)"
    
    # Check for spaces
    if [[ "$AWS_ACCESS_KEY_ID" =~ [[:space:]] ]]; then
        echo -e "${RED}${CROSS} WARNING: AWS_ACCESS_KEY_ID contains spaces!${NC}"
        echo -e "    This will cause authentication failures."
        echo -e "    Fix: export AWS_ACCESS_KEY_ID=\$(echo \"\$AWS_ACCESS_KEY_ID\" | tr -d '[:space:]')"
    fi
    ENV_VAR_SET=true
else
    echo -e "${YELLOW}${WARNING} AWS_ACCESS_KEY_ID not set in environment${NC}"
fi

if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${GREEN}${CHECK} AWS_SECRET_ACCESS_KEY is set${NC}"
    echo -e "    Value: ${AWS_SECRET_ACCESS_KEY:0:5}... (showing first 5 chars)"
    
    # Check for spaces
    if [[ "$AWS_SECRET_ACCESS_KEY" =~ [[:space:]] ]]; then
        echo -e "${RED}${CROSS} WARNING: AWS_SECRET_ACCESS_KEY contains spaces!${NC}"
        echo -e "    This will cause authentication failures."
        echo -e "    Fix: export AWS_SECRET_ACCESS_KEY=\$(echo \"\$AWS_SECRET_ACCESS_KEY\" | tr -d '[:space:]')"
    fi
    ENV_VAR_SET=true
else
    echo -e "${YELLOW}${WARNING} AWS_SECRET_ACCESS_KEY not set in environment${NC}"
fi

if [ -n "$AWS_SESSION_TOKEN" ]; then
    echo -e "${GREEN}${CHECK} AWS_SESSION_TOKEN is set (temporary credentials)${NC}"
    ENV_VAR_SET=true
fi

if [ -n "$AWS_PROFILE" ]; then
    echo -e "${GREEN}${CHECK} AWS_PROFILE is set: ${AWS_PROFILE}${NC}"
else
    echo -e "${YELLOW}${INFO} AWS_PROFILE not set (will use 'default' profile)${NC}"
fi

if [ "$ENV_VAR_SET" = false ]; then
    echo -e "${YELLOW}${INFO} No AWS environment variables set${NC}"
    echo -e "    Credentials will be loaded from ~/.aws/credentials${NC}"
fi
echo ""

# Check 3: AWS Credentials File
echo -e "${BLUE}[3/7] Checking AWS credentials file...${NC}"
if [ -f ~/.aws/credentials ]; then
    echo -e "${GREEN}${CHECK} Credentials file exists: ~/.aws/credentials${NC}"
    
    # Check if default profile exists
    if grep -q "\[default\]" ~/.aws/credentials; then
        echo -e "${GREEN}${CHECK} Default profile found${NC}"
    else
        echo -e "${YELLOW}${WARNING} No [default] profile in credentials file${NC}"
    fi
    
    # List available profiles
    PROFILES=$(grep '^\[' ~/.aws/credentials | tr -d '[]' | tr '\n' ', ' | sed 's/,$//')
    if [ -n "$PROFILES" ]; then
        echo -e "    Available profiles: ${PROFILES}"
    fi
else
    echo -e "${YELLOW}${WARNING} Credentials file not found: ~/.aws/credentials${NC}"
    echo -e "${INFO} Run 'aws configure' to create it${NC}"
fi
echo ""

# Check 4: AWS Config File
echo -e "${BLUE}[4/7] Checking AWS config file...${NC}"
if [ -f ~/.aws/config ]; then
    echo -e "${GREEN}${CHECK} Config file exists: ~/.aws/config${NC}"
    
    REGION=$(aws configure get region 2>/dev/null || echo "")
    if [ -n "$REGION" ]; then
        echo -e "${GREEN}${CHECK} Default region configured: ${REGION}${NC}"
    else
        echo -e "${YELLOW}${WARNING} No default region configured${NC}"
        echo -e "    Set with: aws configure set region us-east-1${NC}"
    fi
else
    echo -e "${YELLOW}${WARNING} Config file not found: ~/.aws/config${NC}"
fi
echo ""

# Check 5: Test AWS Credentials
echo -e "${BLUE}[5/7] Testing AWS credentials with STS GetCallerIdentity...${NC}"
STS_FAILED=false
STS_OUTPUT=$(aws sts get-caller-identity 2>&1) || STS_FAILED=true

if [ "$STS_FAILED" = true ]; then
    echo -e "${RED}${CROSS} AWS credential validation FAILED${NC}"
    echo ""
    echo -e "${RED}Error output:${NC}"
    echo "$STS_OUTPUT"
    echo ""
    echo -e "${YELLOW}Common causes:${NC}"
    echo "  1. Invalid or expired credentials"
    echo "  2. Special characters in secret key not properly quoted"
    echo "  3. Spaces in credentials"
    echo "  4. System clock skew (time difference > 5 minutes)"
    echo "  5. Incorrect AWS region or endpoint"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Verify credentials: aws configure"
    echo '  2. Check for spaces: echo "[$AWS_SECRET_ACCESS_KEY]"'
    echo "  3. Regenerate credentials in AWS IAM Console"
    echo "  4. See TROUBLESHOOTING.md for detailed solutions"
    echo ""
    exit 1
else
    echo -e "${GREEN}${CHECK} AWS credentials are VALID!${NC}"
    echo ""
    echo -e "${GREEN}Account Details:${NC}"
    echo "$STS_OUTPUT" | jq '.' 2>/dev/null || echo "$STS_OUTPUT"
fi
echo ""

# Check 6: System Time
echo -e "${BLUE}[6/7] Checking system time for clock skew...${NC}"
CURRENT_TIME=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
echo -e "${GREEN}${CHECK} Current system time: ${CURRENT_TIME}${NC}"

# Try to get AWS time from an API call
AWS_TIME_RESPONSE=$(aws sts get-caller-identity 2>&1)
if [[ $AWS_TIME_RESPONSE == *"RequestTimeTooSkewed"* ]]; then
    echo -e "${RED}${CROSS} System clock is out of sync with AWS servers!${NC}"
    echo -e "    Fix: sudo ntpdate -s time.nist.gov (Linux/macOS)"
    echo -e "    Fix: w32tm /resync (Windows)"
else
    echo -e "${GREEN}${CHECK} System time appears to be in sync${NC}"
fi
echo ""

# Check 7: Terraform Check
echo -e "${BLUE}[7/7] Checking Terraform installation...${NC}"
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version | head -n 1)
    echo -e "${GREEN}${CHECK} Terraform is installed${NC}"
    echo -e "    Version: ${TERRAFORM_VERSION}"
else
    echo -e "${YELLOW}${WARNING} Terraform is not installed${NC}"
    echo -e "${INFO} Install from: https://www.terraform.io/downloads${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  VERIFICATION SUMMARY              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$STS_FAILED" != true ]; then
    echo -e "${GREEN}${CHECK} All checks passed! You're ready to use Terraform with AWS.${NC}"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "  1. Navigate to a lesson directory (e.g., cd lessons/day03/)"
    echo "  2. Initialize Terraform: terraform init"
    echo "  3. Plan your infrastructure: terraform plan"
    echo "  4. Apply changes: terraform apply"
    echo ""
    echo -e "${GREEN}Happy Terraforming! 🚀${NC}"
else
    echo -e "${RED}${CROSS} Credential validation failed.${NC}"
    echo -e "${YELLOW}Please review the error messages above and fix the issues.${NC}"
    echo -e "${YELLOW}For detailed troubleshooting, see: TROUBLESHOOTING.md${NC}"
    exit 1
fi
