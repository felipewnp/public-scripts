#!/bin/bash

set -uo pipefail

WORKSPACE="WORKSPACE_NAME"
USER_EMAIL="BITBUCKET_USER_EMAIL"
BITBUCKET_API_TOKEN="TOKEN"
VARIABLE_NAME="VARIABLE_NAME_TO_SEARCH" # optional - the variable you want to search for

# Function to make Bitbucket API calls with error handling
bitbucket_api() {
	local endpoint="$1"
	local response
	local http_code

	response=$(curl -s -w "%{http_code}" \
		--user "$USER_EMAIL:$BITBUCKET_API_TOKEN" \
		-H "Accept: application/json" \
		"https://api.bitbucket.org/2.0/$endpoint")

	http_code="${response: -3}"
	response_body="${response%???}"

	if [[ "$http_code" -ge 400 ]]; then
		echo "Error: API request failed with HTTP $http_code for endpoint: $endpoint" >&2
		return 1
	fi

	echo "$response_body"
}

# Function to get repository list with pagination
get_repositories() {
	local next_url="repositories/$WORKSPACE?pagelen=100"
	local repos=""
	local response
	local page=1

	echo "Fetching repositories from workspace: $WORKSPACE" >&2

	while [[ -n "$next_url" ]]; do
		echo "Fetching page $page..." >&2
		response=$(bitbucket_api "$next_url")
		if [[ $? -ne 0 ]]; then
			echo "Error: Failed to fetch repositories from Bitbucket API" >&2
			return 1
		fi

		# Check if we got a valid response with repositories
		if ! echo "$response" | jq -e '.values' >/dev/null 2>&1; then
			echo "Error: Invalid API response or no repositories found" >&2
			return 1
		fi

		# Extract repository names
		local page_repos
		page_repos=$(echo "$response" | jq -r '.values[]? | .name')

		if [[ -n "$page_repos" ]]; then
			repos+="$page_repos"$'\n'
			echo "Found $(echo "$page_repos" | wc -l) repositories on page $page" >&2
		fi

		# Check if there's a next page
		next_url=$(echo "$response" | jq -r '.next // empty')
		if [[ "$next_url" == "null" ]] || [[ -z "$next_url" ]]; then
			break
		fi
		# Remove the API base URL if present
		next_url="${next_url#https://api.bitbucket.org/2.0/}"
		((page++))
	done

	echo "$repos"
}

# Function to get repository variables with pagination
get_repository_variables() {
	local repo_name="$1"
	local next_url="repositories/$WORKSPACE/$repo_name/pipelines_config/variables/?pagelen=100"
	local all_variables=""
	local response

	while [[ -n "$next_url" ]]; do
		response=$(bitbucket_api "$next_url")
		if [[ $? -ne 0 ]]; then
			# If we can't fetch variables for this repo, return empty
			break
		fi

		# Check if we got a valid response
		if echo "$response" | jq -e '.values' >/dev/null 2>&1; then
			local page_vars
			page_vars=$(echo "$response" | jq -r '.values[]? | "\(.key)=\(.value)"')
			if [[ -n "$page_vars" ]]; then
				all_variables+="$page_vars"$'\n'
			fi
		fi

		# Check if there's a next page
		next_url=$(echo "$response" | jq -r '.next // empty')
		if [[ "$next_url" == "null" ]] || [[ -z "$next_url" ]]; then
			break
		fi
		# Remove the API base URL if present
		next_url="${next_url#https://api.bitbucket.org/2.0/}"
	done

	echo "$all_variables"
}

# Function to check if variable exists in repository
check_repository_variable() {
	local repo_name="$1"
	local var_name="${VARIABLE_NAME}"

	# Get all variables for the repository
	variables=$(get_repository_variables "$repo_name")

	# Check if the specific variable exists
	variable_value=$(echo "$variables" | grep "^$var_name=" | cut -d'=' -f2-)

	if [[ -n "$variable_value" ]]; then
		echo "Repository: $repo_name"
		echo "  Variable '$var_name' found: $variable_value"
		echo "---"
		return 0
	else
		return 1
	fi
}

# Main script
echo "Bitbucket Repository Variable Scanner"
echo "======================================"
echo "Workspace: $WORKSPACE"
echo "User Email: $USER_EMAIL"
echo "Searching for variable: $VARIABLE_NAME"
echo ""

# Check if jq is installed
if ! command -v jq &>/dev/null; then
	echo "Error: jq is required but not installed. Please install jq."
	echo "Ubuntu/Debian: sudo apt-get install jq"
	echo "macOS: brew install jq"
	exit 1
fi

# Check if curl is installed
if ! command -v curl &>/dev/null; then
	echo "Error: curl is required but not installed. Please install curl."
	exit 1
fi

# Validate that variables are set
if [[ -z "$WORKSPACE" ]] || [[ "$WORKSPACE" == "your-workspace-name-here" ]]; then
	echo "Error: Please set the WORKSPACE variable in the script"
	exit 1
fi

if [[ -z "$USER_EMAIL" ]] || [[ "$USER_EMAIL" == "your-email@example.com" ]]; then
	echo "Error: Please set the USER_EMAIL variable in the script"
	exit 1
fi

if [[ -z "$BITBUCKET_API_TOKEN" ]] || [[ "$BITBUCKET_API_TOKEN" == "your-api-token-here" ]]; then
	echo "Error: Please set the BITBUCKET_API_TOKEN variable in the script"
	echo "Get your token from: https://bitbucket.org/account/settings/app-passwords/"
	exit 1
fi

if [[ -z "$VARIABLE_NAME" ]] || [[ "$VARIABLE_NAME" == "YOUR_VARIABLE_NAME" ]]; then
	echo "Error: Please set the VARIABLE_NAME variable in the script"
	exit 1
fi

echo "Fetching repositories..."
repositories=$(get_repositories)
if [[ $? -ne 0 ]] || [[ -z "$repositories" ]]; then
	echo "Error: Failed to fetch repositories or no repositories found"
	exit 1
fi

# Count repositories and remove empty lines
repositories=$(echo "$repositories" | sed '/^$/d')
repo_count=$(echo "$repositories" | wc -l)

echo ""
echo "Scanning $repo_count repositories for variable: $VARIABLE_NAME"
echo "=============================================================="

found_count=0

# Process each repository
while IFS= read -r repo; do
	if [[ -n "$repo" ]]; then
		if check_repository_variable "$repo"; then
			((found_count++))
		fi
	fi
done <<<"$repositories"

echo ""
if [[ $found_count -eq 0 ]]; then
	echo "No repositories found with variable: $VARIABLE_NAME"
else
	echo "Found $found_count repositories with variable: $VARIABLE_NAME"
fi
