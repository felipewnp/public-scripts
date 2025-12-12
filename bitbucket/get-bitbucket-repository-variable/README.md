# Bitbucket Repository Variable Scanner

A Bash script to scan through all repositories in a Bitbucket workspace and search for specific pipeline variables.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Output Examples](#output-examples)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [License](#license)

## Overview

This script provides an automated way to search for specific pipeline variables across all repositories in a Bitbucket workspace. It's particularly useful for:

- **Security Audits**: Finding repositories containing specific sensitive variables
- **Compliance Checks**: Ensuring all repositories have required configuration variables
- **Inventory Management**: Tracking where specific variables are used
- **Migration Assistance**: Identifying repositories that need variable updates

## Features

- 🔍 **Comprehensive Scanning**: Searches through all repositories in a workspace
- 📄 **Pagination Support**: Handles large workspaces with many repositories
- 🎯 **Targeted Search**: Looks for specific variable names
- 📊 **Detailed Output**: Shows which repositories contain the variable and its value
- 🛡️ **Error Handling**: Robust error checking and informative error messages
- 🔄 **API Rate Handling**: Properly handles Bitbucket API pagination
- 📋 **Dependency Checks**: Verifies required tools are installed

## Prerequisites

### Required Tools

- **jq**: JSON processor for parsing API responses
- **curl**: HTTP client for making API requests
- **bash**: Shell environment

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

### Bitbucket Access

1. **Bitbucket Account**: Access to the workspace you want to scan
2. **API Token**: App password with appropriate permissions:
   - `repository:read` - To read repository information
   - `pipeline:read` - To read pipeline variables

## Installation

1. **Download the script**:

   ```bash
   curl -O https://raw.githubusercontent.com/your-username/bitbucket-scripts/main/get-bitbucket-variable.sh
   ```

2. **Make it executable**:

   ```bash
   chmod +x get-bitbucket-variable.sh
   ```

3. **Verify installation**:

   ```bash
   ./get-bitbucket-variable.sh --help
   ```

## Configuration

Edit the script to set your Bitbucket credentials:

```bash
# Open the script in your preferred editor
nano get-bitbucket-variable.sh
```

Update these variables at the top of the script:

```bash
WORKSPACE="your-workspace-slug"            # Your Bitbucket workspace name/slug
USER_EMAIL="your-email@example.com"        # Your Bitbucket account email
BITBUCKET_API_TOKEN="your-api-token"       # Your Bitbucket app password
VARIABLE_NAME="TARGET_VARIABLE_NAME"       # The variable to search for
```

### Getting Your Bitbucket App Password

1. Go to [Bitbucket App Passwords](https://bitbucket.org/account/settings/app-passwords/)
2. Click **Create app password**
3. Set permissions:
   - Repository: **Read**
   - Pipelines: **Read**
4. Copy the generated token (you won't see it again)

## Usage

### Basic Usage

```bash
./get-bitbucket-variable.sh
```

The script will:
1. Connect to the Bitbucket API
2. Fetch all repositories in the workspace
3. Search each repository for the specified variable
4. Display results

### Example Scenarios

#### Finding API Keys
```bash
# Search for repositories containing API keys
# Edit VARIABLE_NAME="API_KEY" in the script
./get-bitbucket-variable.sh
```

#### Compliance Check
```bash
# Verify all repositories have required variables
# Edit VARIABLE_NAME="COMPLIANCE_VERSION" in the script
./get-bitbucket-variable.sh
```

### Expected Output

```
Bitbucket Repository Variable Scanner
======================================
Workspace: my-workspace
User Email: user@example.com
Searching for variable: API_KEY

Fetching repositories...
Fetching page 1...
Found 25 repositories on page 1
Fetching page 2...
Found 15 repositories on page 2

Scanning 40 repositories for variable: API_KEY
==============================================================

Repository: frontend-app
  Variable 'API_KEY' found: sk_live_1234567890abcdef
---
Repository: backend-service
  Variable 'API_KEY' found: sk_test_9876543210fedcba
---
Repository: data-processor
  Variable 'API_KEY' found: sk_live_a1b2c3d4e5f6g7h8
---

Found 3 repositories with variable: API_KEY
```

## Output Examples

### Variable Found
```
Repository: my-repo
  Variable 'DATABASE_URL' found: postgres://user:pass@host:5432/db
---
```

### No Variables Found
```
No repositories found with variable: NON_EXISTENT_VAR
```

### Empty Workspace
```
Error: Failed to fetch repositories or no repositories found
```

## Troubleshooting

### Common Issues

#### 1. Authentication Errors
```
Error: API request failed with HTTP 401 for endpoint: repositories/workspace?pagelen=100
```
**Solution**: Verify your API token has correct permissions and hasn't expired.

#### 2. Workspace Not Found
```
Error: API request failed with HTTP 404 for endpoint: repositories/workspace?pagelen=100
```
**Solution**: Check the workspace slug is correct.

#### 3. Missing jq
```
Error: jq is required but not installed.
```
**Solution**: Install jq using your package manager.

#### 4. Permission Denied
```
Error: API request failed with HTTP 403 for endpoint: repositories/workspace/repo/pipelines_config/variables/
```
**Solution**: Ensure your app password has `pipeline:read` permission.

#### 5. Rate Limiting
If you have many repositories, you might hit API rate limits.
**Solution**: The script includes pagination to minimize requests.

### Debug Mode
Add `set -x` at the beginning of the script for detailed debugging:

```bash
#!/bin/bash
set -x  # Add this line
set -uo pipefail
```

## Security Considerations

⚠️ **Important Security Notes**:

1. **Store Credentials Securely**: Never commit the script with real credentials
2. **Use Environment Variables**: Consider modifying the script to read credentials from environment variables
3. **Limit Token Permissions**: Use app passwords with minimal required permissions
4. **Rotate Tokens Regularly**: Update API tokens periodically
5. **Review Output Carefully**: Variable values may contain sensitive information

### Alternative: Environment Variables (Recommended)
Modify the script to use environment variables:

```bash
# Replace hardcoded credentials with:
WORKSPACE="${BITBUCKET_WORKSPACE:-your-workspace-slug}"
USER_EMAIL="${BITBUCKET_USER_EMAIL:-your-email@example.com}"
BITBUCKET_API_TOKEN="${BITBUCKET_API_TOKEN:-your-api-token}"
```

Then run with:
```bash
export BITBUCKET_WORKSPACE="my-workspace"
export BITBUCKET_USER_EMAIL="user@example.com"
export BITBUCKET_API_TOKEN="your-token-here"
./get-bitbucket-variable.sh
```

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

**Disclaimer**: This tool accesses sensitive Bitbucket data. Use responsibly and ensure you have proper authorization. The authors are not responsible for any misuse or damages resulting from the use of this script.