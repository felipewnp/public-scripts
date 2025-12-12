#!/bin/bash

set -uo pipefail

WORKSPACE=
USER_EMAIL=
BITBUCKET_API_TOKEN=
TARGET_VARIABLE_KEY=
TARGET_VARIABLE_VALUE=
TARGET_VARIABLE_SECURED=

# CONFIGURABLE FILTER: Set to "api-" to filter repositories starting with api-
# Set to "" (empty) to process ALL repositories
REPO_NAME_FILTER="web-"

########################################
# Helpers
########################################

# Normalizes a UUID: strips whitespace only (keeps braces if present)
normalize_uuid_raw() {
	echo -n "$1" | tr -d '[:space:]'
}

# Returns a URL component for Bitbucket that looks like: %7Buuid%7D
# Accepts "uuid" or "{uuid}" and outputs "%7Buuid%7D"
uuid_url_component() {
	local u
	u="$(normalize_uuid_raw "$1")"
	u="${u#\{}" # strip leading {
	u="${u%\}}" # strip trailing }
	printf '%%7B%s%%7D' "$u"
}

########################################
# Bitbucket API wrapper
########################################

bitbucket_api() {
	local endpoint="$1"
	local method="${2:-GET}"
	local data="${3:-}"
	local response
	local http_code

	local curl_cmd=(curl -s -w "%{http_code}"
		--user "$USER_EMAIL:$BITBUCKET_API_TOKEN"
		-H "Accept: application/json"
		-X "$method"
	)

	# Only add Content-Type + body if we actually have data
	if [[ -n "$data" ]]; then
		curl_cmd+=(-H "Content-Type: application/json" -d "$data")
	fi

	curl_cmd+=("https://api.bitbucket.org/2.0/$endpoint")

	response=$("${curl_cmd[@]}")
	http_code="${response: -3}"
	response_body="${response%???}"

	if [[ "$http_code" -ge 400 ]]; then
		echo "Error: API request failed with HTTP $http_code for endpoint: $endpoint" >&2
		echo "Response: $response_body" >&2
		return 1
	fi

	echo "$response_body"
}

########################################
# Get repositories
########################################

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

		# Extract repository slugs/names
		local page_repos
		page_repos=$(echo "$response" | jq -r '.values[]? | "\(.slug)"')

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

########################################
# Check if variable exists in repo
########################################

check_variable_exists() {
	local repo_slug="$1"
	local response

	response=$(bitbucket_api "repositories/$WORKSPACE/$repo_slug/pipelines_config/variables?pagelen=100")
	if [[ $? -ne 0 ]]; then
		echo "" # Error / no variables
		return 1
	fi

	# If variable exists, return its UUID (Bitbucket-style, usually with braces)
	local uuid
	uuid=$(echo "$response" | jq -r --arg key "$TARGET_VARIABLE_KEY" \
		'.values[]? | select(.key == $key) | .uuid')

	if [[ -n "$uuid" && "$uuid" != "null" ]]; then
		echo "$uuid"
		return 0
	fi

	echo ""
	return 1
}

########################################
# Add / Update variable
########################################

add_variable_to_repo() {
	local repo_slug="$1"

	echo "  Processing variable '$TARGET_VARIABLE_KEY' for repository '$repo_slug'..."

	# Check if variable already exists and get its UUID (as Bitbucket returns it)
	local existing_uuid
	existing_uuid=$(check_variable_exists "$repo_slug" || true)

	# JSON payload for POST (includes key)
	local json_post
	json_post=$(jq -n \
		--arg key "$TARGET_VARIABLE_KEY" \
		--arg value "$TARGET_VARIABLE_VALUE" \
		--argjson secured "$TARGET_VARIABLE_SECURED" \
		'{
      "key": $key,
      "value": $value,
      "secured": $secured
    }')

	# JSON payload for PUT (value + secured only)
	local json_put
	json_put=$(jq -n \
		--arg value "$TARGET_VARIABLE_VALUE" \
		--argjson secured "$TARGET_VARIABLE_SECURED" \
		'{
      "value": $value,
      "secured": $secured
    }')

	local response

	if [[ -n "$existing_uuid" ]]; then
		# Build URL component: %7Buuid%7D
		local existing_uuid_url
		existing_uuid_url="$(uuid_url_component "$existing_uuid")"

		echo "  Updating existing variable (UUID: $existing_uuid)..."
		response=$(bitbucket_api \
			"repositories/$WORKSPACE/$repo_slug/pipelines_config/variables/$existing_uuid_url" \
			"PUT" \
			"$json_put")
	else
		echo "  Creating variable..."
		response=$(bitbucket_api \
			"repositories/$WORKSPACE/$repo_slug/pipelines_config/variables" \
			"POST" \
			"$json_post")
	fi

	if [[ $? -eq 0 ]]; then
		echo "  ✓ Successfully set variable"
		return 0
	else
		echo "  ✗ Failed to set variable"
		return 1
	fi
}

########################################
# Main
########################################

echo "Bitbucket Repository Variable Setter"
echo "===================================="
echo "Workspace: $WORKSPACE"
echo "User Email: $USER_EMAIL"
echo "Variable to set: $TARGET_VARIABLE_KEY=$TARGET_VARIABLE_VALUE"
if [[ -n "$REPO_NAME_FILTER" ]]; then
	echo "Repository filter: repositories starting with '$REPO_NAME_FILTER'"
else
	echo "Repository filter: ALL repositories (no filter)"
fi
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
if [[ -z "$WORKSPACE" ]] || [[ "$WORKSPACE" == "WORKSPACE_NAME" ]]; then
	echo "Error: Please set the WORKSPACE variable in the script"
	exit 1
fi

if [[ -z "$USER_EMAIL" ]] || [[ "$USER_EMAIL" == "BITBUCKET_USER_EMAIL" ]]; then
	echo "Error: Please set the USER_EMAIL variable in the script"
	exit 1
fi

if [[ -z "$BITBUCKET_API_TOKEN" ]] || [[ "$BITBUCKET_API_TOKEN" == "TOKEN" ]]; then
	echo "Error: Please set the BITBUCKET_API_TOKEN variable in the script"
	echo "Get your token from: https://bitbucket.org/account/settings/app-passwords/"
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
echo "Found $repo_count repositories in workspace '$WORKSPACE'"

# Apply filter if specified
if [[ -n "$REPO_NAME_FILTER" ]]; then
	filtered_repositories=$(echo "$repositories" | grep "^$REPO_NAME_FILTER" || true)
	filtered_count=$(echo "$filtered_repositories" | wc -l)
	echo "Filter matched $filtered_count repositories starting with '$REPO_NAME_FILTER'"
	repositories="$filtered_repositories"
else
	filtered_count=$repo_count
	echo "Processing ALL $filtered_count repositories (no filter applied)"
fi

echo ""
echo "Setting variable '$TARGET_VARIABLE_KEY' to '$TARGET_VARIABLE_VALUE'"
echo "===================================="

processed_count=0
success_count=0

# Process each repository
while IFS= read -r repo_slug; do
	if [[ -n "$repo_slug" ]]; then
		((processed_count++))
		echo ""
		echo "[$processed_count/$filtered_count] Processing: $repo_slug"

		if add_variable_to_repo "$repo_slug"; then
			((success_count++))
		fi
		# exit 0
	fi
done <<<"$repositories"

echo ""
echo "Summary"
echo "===================================="
echo "Total repositories in workspace: $repo_count"
echo "Repositories matching filter: $filtered_count"
echo "Repositories processed: $processed_count"
echo "Successfully updated: $success_count"

if [[ $processed_count -gt 0 ]] && [[ $success_count -eq $processed_count ]]; then
	echo "Status: ✓ All repositories updated successfully"
	exit 0
elif [[ $success_count -gt 0 ]]; then
	echo "Status: ⚠ Partially successful ($((processed_count - success_count)) failures)"
	exit 1
else
	echo "Status: ✗ All updates failed"
	exit 1
fi
