# Bitbucket Repository Variable Setter

A Bash script to batch set or update pipeline variables across multiple repositories in a Bitbucket workspace.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Examples](#examples)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [License](#license)

## Overview

This script automates the process of setting or updating pipeline variables across multiple Bitbucket repositories. It's designed for bulk operations and supports both creating new variables and updating existing ones. Ideal for:

- **Batch Configuration**: Setting common variables across multiple repositories
- **Security Updates**: Rotating API keys or secrets across all projects
- **Environment Setup**: Configuring environment-specific variables
- **Migration Tasks**: Standardizing variable naming conventions
- **Compliance Enforcement**: Ensuring required variables are present

## Features

- 🔄 **Smart Update Logic**: Creates new variables or updates existing ones automatically
- 🎯 **Repository Filtering**: Optional filtering by repository name prefix
- 📊 **Detailed Reporting**: Comprehensive progress tracking and success/failure reporting
- 🛡️ **Error Handling**: Robust error checking with informative messages
- 🔍 **Variable Detection**: Checks if variables already exist before creating
- 📋 **Pagination Support**: Handles workspaces with hundreds of repositories
- ⚡ **Efficient API Calls**: Minimizes API requests with proper UUID handling
- 🔐 **Secured Variable Support**: Supports both regular and secured (secret) variables

## Prerequisites

### Required Tools

- **jq**: JSON processor for parsing API responses
- **curl**: HTTP client for making API requests
- **bash**: Shell environment (version 4.0 or higher)

### Installation Commands

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install jq curl

# macOS
brew install jq curl

# RHEL/CentOS/Fedora
sudo yum install jq curl
# or
sudo dnf install jq curl
```

### Bitbucket Permissions

1. **Bitbucket Account**: Access to the workspace you want to modify
2. **API Token**: App password with appropriate permissions:
   - `repository:read` - To read repository information
   - `pipeline:write` - To create/update pipeline variables

## Installation

1. **Download the script**:

   ```bash
   curl -O https://raw.githubusercontent.com/your-username/bitbucket-scripts/main/set-bitbucket-repository-variable.sh
   ```

2. **Make it executable**:

   ```bash
   chmod +x set-bitbucket-repository-variable.sh
   ```

3. **Verify installation**:

   ```bash
   ./set-bitbucket-repository-variable.sh
   # This will show configuration errors if variables aren't set
   ```

## Configuration

Edit the script to configure your settings:

```bash
# Open the script in your preferred editor
nano set-bitbucket-repository-variable.sh
```

### Required Configuration

Update these variables at the top of the script:

```bash
WORKSPACE="your-workspace-slug"            # Your Bitbucket workspace name/slug
USER_EMAIL="your-email@example.com"        # Your Bitbucket account email
BITBUCKET_API_TOKEN="your-api-token"       # Your Bitbucket app password
TARGET_VARIABLE_KEY="VARIABLE_NAME"        # The variable name to set
TARGET_VARIABLE_VALUE="variable-value"     # The value to set
TARGET_VARIABLE_SECURED=false              # true for secrets, false for regular variables
```

### Optional Configuration

```bash
# Filter repositories by name prefix (e.g., only "web-" repositories)
# Set to "" (empty) to process ALL repositories
REPO_NAME_FILTER="web-"
```

### Getting Your Bitbucket App Password

1. Go to [Bitbucket App Passwords](https://bitbucket.org/account/settings/app-passwords/)
2. Click **Create app password**
3. Set permissions:
   - Repository: **Read**
   - Pipelines: **Write**
4. Copy the generated token (you won't see it again)

## Usage

### Basic Usage

1. **Configure the script** with your credentials and target variable
2. **Run the script**:

   ```bash
   ./set-bitbucket-repository-variable.sh
   ```

The script will:
1. Connect to Bitbucket API
2. Fetch all repositories (or filtered subset)
3. Check each repository for existing variable
4. Create or update the variable as needed
5. Provide detailed progress and summary

### Usage Examples

#### Example 1: Set Environment Variable
```bash
# Set DATABASE_URL across all repositories
TARGET_VARIABLE_KEY="DATABASE_URL"
TARGET_VARIABLE_VALUE="postgres://user:pass@localhost:5432/mydb"
TARGET_VARIABLE_SECURED=false
REPO_NAME_FILTER=""  # All repositories
```

#### Example 2: Set Secret API Key
```bash
# Set a secured API key for frontend repositories
TARGET_VARIABLE_KEY="API_KEY"
TARGET_VARIABLE_VALUE="sk_live_1234567890abcdef"
TARGET_VARIABLE_SECURED=true
REPO_NAME_FILTER="frontend-"  # Only repositories starting with "frontend-"
```

#### Example 3: Update Configuration Version
```bash
# Update configuration version for web services
TARGET_VARIABLE_KEY="CONFIG_VERSION"
TARGET_VARIABLE_VALUE="v2.1.0"
TARGET_VARIABLE_SECURED=false
REPO_NAME_FILTER="web-"  # Only repositories starting with "web-"
```

### Output Examples

#### Successful Run
```
Bitbucket Repository Variable Setter
====================================
Workspace: my-org
User Email: admin@example.com
Variable to set: API_KEY=sk_live_1234567890abcdef
Repository filter: repositories starting with 'web-'

Fetching repositories...
Fetching page 1...
Found 50 repositories on page 1

Found 50 repositories in workspace 'my-org'
Filter matched 12 repositories starting with 'web-'

Setting variable 'API_KEY' to 'sk_live_1234567890abcdef'
====================================

[1/12] Processing: web-frontend
  Processing variable 'API_KEY' for repository 'web-frontend'...
  Creating variable...
  ✓ Successfully set variable

[2/12] Processing: web-backend
  Processing variable 'API_KEY' for repository 'web-backend'...
  Updating existing variable (UUID: {12345678-1234-1234-1234-123456789abc})...
  ✓ Successfully set variable

... (more repositories) ...

Summary
====================================
Total repositories in workspace: 50
Repositories matching filter: 12
Repositories processed: 12
Successfully updated: 12
Status: ✓ All repositories updated successfully
```

#### Partial Success
```
Summary
====================================
Total repositories in workspace: 50
Repositories matching filter: 12
Repositories processed: 12
Successfully updated: 10
Status: ⚠ Partially successful (2 failures)
```

## Advanced Usage

### Using Environment Variables (Recommended for Security)

Modify the script to use environment variables:

```bash
# In the script, change hardcoded values to:
WORKSPACE="${BITBUCKET_WORKSPACE:-your-workspace-slug}"
USER_EMAIL="${BITBUCKET_USER_EMAIL:-your-email@example.com}"
BITBUCKET_API_TOKEN="${BITBUCKET_API_TOKEN:-your-api-token}"
```

Then run with:

```bash
export BITBUCKET_WORKSPACE="my-org"
export BITBUCKET_USER_EMAIL="admin@example.com"
export BITBUCKET_API_TOKEN="your-token-here"
export TARGET_VARIABLE_KEY="API_KEY"
export TARGET_VARIABLE_VALUE="sk_live_1234567890abcdef"
export TARGET_VARIABLE_SECURED=true
export REPO_NAME_FILTER="web-"

./set-bitbucket-repository-variable.sh
```

### Dry Run Mode

Add a dry run mode to preview changes:

```bash
# Add at the beginning of add_variable_to_repo() function:
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "  [DRY RUN] Would set variable '$TARGET_VARIABLE_KEY' to '$TARGET_VARIABLE_VALUE'"
    return 0
fi
```

Run with:

```bash
DRY_RUN=true ./set-bitbucket-repository-variable.sh
```

### Batch Processing Multiple Variables

Create a wrapper script for multiple variables:

```bash
#!/bin/bash
# set-multiple-variables.sh

export BITBUCKET_WORKSPACE="my-org"
export BITBUCKET_USER_EMAIL="admin@example.com"
export BITBUCKET_API_TOKEN="your-token"

# Array of variables to set
variables=(
    "API_KEY:sk_live_1234567890abcdef:true"
    "ENVIRONMENT:production:false"
    "LOG_LEVEL:info:false"
)

for var in "${variables[@]}"; do
    IFS=':' read -r key value secured <<< "$var"
    export TARGET_VARIABLE_KEY="$key"
    export TARGET_VARIABLE_VALUE="$value"
    export TARGET_VARIABLE_SECURED="$secured"
    
    echo "Setting variable: $key"
    ./set-bitbucket-repository-variable.sh
    echo ""
done
```

## Troubleshooting

### Common Issues

#### 1. Authentication Errors
```
Error: API request failed with HTTP 401 for endpoint: repositories/workspace?pagelen=100
```
**Solution**: Verify your API token has correct permissions and hasn't expired.

#### 2. Permission Denied
```
Error: API request failed with HTTP 403 for endpoint: repositories/workspace/repo/pipelines_config/variables/
```
**Solution**: Ensure your app password has `pipeline:write` permission.

#### 3. Invalid Workspace
```
Error: Failed to fetch repositories or no repositories found
```
**Solution**: Check the workspace slug is correct and you have access.

#### 4. JSON Parsing Errors
```
parse error: Invalid numeric literal at line 1, column 10
```
**Solution**: Install the latest version of jq.

#### 5. Variable Already Exists (as different type)
If a variable exists as secured and you try to set it as unsecured (or vice versa), Bitbucket may reject the update.
**Solution**: Delete the variable first through Bitbucket UI, then run the script.

### Debug Mode

Add debug output for troubleshooting:

```bash
# Add at the beginning of the script
set -x  # Enable debug mode
```

Or run with:

```bash
bash -x set-bitbucket-repository-variable.sh
```

## Security Considerations

⚠️ **Important Security Notes**:

1. **Never Commit Credentials**: The script contains credential placeholders - never commit with real credentials
2. **Use Environment Variables**: For production use, modify the script to read from environment variables
3. **Minimum Permissions**: Use app passwords with only the necessary permissions
4. **Audit Access**: Regularly review who has access to your Bitbucket tokens
5. **Rotate Tokens**: Update API tokens periodically
6. **Secured Variables**: Use `TARGET_VARIABLE_SECURED=true` for sensitive values (secrets)

### Best Practices

1. **Test First**: Always test with a single repository before batch operations
2. **Backup**: Export your current variables before making bulk changes
3. **Review**: Double-check variable names and values before running
4. **Monitor**: Watch for failed updates and investigate the cause

## License

This script is licensed under the GNU Affero General Public License v3.0.

### GNU Affero General Public License v3.0

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

### Key License Terms:
- You may use, modify, and distribute this software
- You must disclose the source code when you distribute modified versions
- You must license derivative works under the same license
- Network use (SaaS) counts as distribution and requires source disclosure

For the complete license text, see the [LICENSE](LICENSE) file or visit [https://www.gnu.org/licenses/agpl-3.0.html](https://www.gnu.org/licenses/agpl-3.0.html).

---

**Disclaimer**: This tool modifies Bitbucket pipeline variables. Use with caution and ensure you have proper authorization. The authors are not responsible for any misuse, data loss, or damages resulting from the use of this script.