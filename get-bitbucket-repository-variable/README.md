# Bitbucket Repository Variable Scanner

A Bash script to scan all repositories in a Bitbucket workspace and find repositories that contain a specific pipeline variable.

## Features

- Lists all repositories in a Bitbucket workspace
- Scans each repository for a specific pipeline variable
- Only displays repositories that contain the target variable
- Handles pagination for large workspaces
- Provides summary statistics

## Prerequisites

- `curl` - for making API requests
- `jq` - for parsing JSON responses
- Bitbucket API token with appropriate permissions

## Installation

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/felipewnp/public-scripts/main/get-bitbucket-variable/get-bitbucket-variable.sh
   chmod +x get-bitbucket-variable.sh
   ```

2. **Install dependencies:**

   **Ubuntu/Debian:**
   ```bash
   sudo apt-get update
   sudo apt-get install curl jq
   ```

   **macOS:**
   ```bash
   brew install curl jq
   ```

   **CentOS/RHEL:**
   ```bash
   sudo yum install curl jq
   ```

## Configuration

Edit the script file and set the following variables in the configuration section:

```bash
WORKSPACE="your-workspace-name"
USER_EMAIL="your-email@example.com"
BITBUCKET_API_TOKEN="your-api-token-here"
VARIABLE_NAME="VARIABLE_NAME_TO_SEARCH"
```

### Getting Your Bitbucket API Token

1. Go to [Bitbucket App Passwords](https://bitbucket.org/account/settings/app-passwords/)
2. Click **Create** 
3. Give it a descriptive name (e.g., "variable-scanner")
4. Set the following permissions:
   - **Repository: Read**
   - **Pipeline: Read**
5. Copy the generated token

## Usage

### Basic Usage
```bash
./get-bitbucket-variable.sh
```

### Example Output
```
Bitbucket Repository Variable Scanner
======================================
Workspace: my-company
User Email: user@company.com
Searching for variable: DEPLOYMENT_ENV

Fetching repositories...
Fetching page 1...
Found 25 repositories on page 1

Scanning 25 repositories for variable: DEPLOYMENT_ENV
==============================================================

Repository: frontend-app
  Variable 'DEPLOYMENT_ENV' found: production
---
Repository: backend-service
  Variable 'DEPLOYMENT_ENV' found: staging
---

Found 2 repositories with variable: DEPLOYMENT_ENV
```

### Use Cases

- **Find repositories with specific configuration:** Locate all repos that use a particular environment variable
- **Audit security variables:** Check which repositories contain sensitive variables
- **Migration assistance:** Identify repositories that need variable updates during migrations
- **Configuration management:** Track which services use specific configuration values

## API Permissions Required

The Bitbucket API token needs the following permissions:
- `repository:read` - to list repositories in the workspace
- `pipeline:read` - to read pipeline variables

## Error Handling

The script handles common errors:
- Invalid credentials
- Network connectivity issues
- Missing dependencies (`curl`, `jq`)
- Invalid workspace name
- API rate limiting (automatic retry with pagination)

## Troubleshooting

### Common Issues

1. **"Error: API request failed with HTTP 401"**
   - Check your `USER_EMAIL` and `BITBUCKET_API_TOKEN`
   - Verify the token has not expired

2. **"Error: API request failed with HTTP 403"**
   - Ensure the token has the required permissions
   - Check that you have access to the workspace

3. **"Error: Invalid API response or no repositories found"**
   - Verify the `WORKSPACE` name is correct
   - Check that the workspace contains repositories

4. **"jq: command not found"**
   - Install jq using your package manager

### Debug Mode

For detailed debugging, you can modify the script to show more output by removing the `>&2` redirects from the echo statements in the functions.

## Security Considerations

- Store the script in a secure location
- Use Bitbucket app passwords with minimal required permissions
- Consider using environment variables instead of hardcoding credentials
- Regularly rotate your API tokens

## Environment Variables Alternative

Instead of hardcoding values in the script, you can use environment variables:

```bash
export WORKSPACE="your-workspace"
export USER_EMAIL="your-email@company.com"
export BITBUCKET_API_TOKEN="your-token"
export VARIABLE_NAME="TARGET_VAR"
./get-bitbucket-variable.sh
```

And modify the script to use:
```bash
WORKSPACE="${WORKSPACE:-your-workspace-name-here}"
USER_EMAIL="${USER_EMAIL:-your-email@example.com}"
BITBUCKET_API_TOKEN="${BITBUCKET_API_TOKEN:-your-api-token-here}"
VARIABLE_NAME="${VARIABLE_NAME:-YOUR_VARIABLE_NAME}"
```

## License

MIT License - feel free to use and modify as needed.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request
