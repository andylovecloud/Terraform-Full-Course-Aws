# Day 1: Terraform Installation & Setup Guide

Objective: Install the Terraform CLI and prepare the local development environment for Infrastructure as Code (IaC).

# 1. Installation

🍎 macOS

The easiest way to install Terraform on macOS is via [Homebrew](https://brew.sh/).

## 1. Install the HashiCorp tap
```
brew tap hashicorp/tap
```

## 2. Install Terraform
```
brew install hashicorp/tap/terraform
```

## 3. Update to the latest version (if you already have it)
```
brew upgrade hashicorp/tap/terraform
```

🪟 Windows

You can install via [Chocolatey](https://chocolatey.org/) or manually via binary.

Using Chocolatey (Administrator PowerShell):
```
choco install terraform
```

Using Scoop:
```
scoop install terraform
```

🐧 Linux (Ubuntu/Debian)

Ensure your system is up to date and you have the gnupg, software-properties-common, and curl packages installed.

## 1. Install HashiCorp GPG Key
```
wget -O- [https://apt.releases.hashicorp.com/gpg](https://apt.releases.hashicorp.com/gpg) | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

## 2. Add the official HashiCorp repository
```
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
[https://apt.releases.hashicorp.com](https://apt.releases.hashicorp.com) $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
```

## 3. Update and Install
```
sudo apt update && sudo apt install terraform
```

# 2. Verification

Verify the installation was successful by checking the version.
```
terraform -version
```

Expected Output: `Terraform v1.x.x`

# 3. Configuration: Enable Tab Autocomplete

Why? This boosts speed and reduces syntax errors by allowing you to press `Tab` to complete commands (e.g., typing `terraform pl` + `Tab` becomes `terraform plan`).

**How to enable**:
Run the following command in your terminal:
```
terraform -install-autocomplete
```

Note: You may need to restart your terminal shell (or run source `~/.bashrc / source ~/.zshrc`) for changes to take effect.

# 4. GitHub Repo Setup (Important!)

When working with Terraform in a Git repository, there are files you must not commit (like secret variables or local state files).

Create a `.gitignore` file in the root of your repository with the following content:

```
# .gitignore

# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data, such as
# password, private keys, and other secrets.
*.tfvars
*.tfvars.json

# Ignore override files as they are usually used to override resources locally and so
# are not checked in
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Include override files you do wish to add to version control using negated pattern
# !example_override.tf

# .terraform.lock.hcl should be maintained if using Terraform 0.14+
# !.terraform.lock.hcl

```
