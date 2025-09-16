#!/bin/bash

set -euo pipefail

# Usage: ./script.sh <api-gateway-id> [specific-stage-name]
# This script handles API Gateways with separate API definitions per stage

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <api-gateway-id> [specific-stage-name]"
    echo "Example: $0 abc123def456"
    echo "Example: $0 abc123def456 api-one"
    exit 1
fi

API_GATEWAY_ID=$1
SPECIFIC_STAGE=$2

# Function to check AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS CLI is not configured properly"
        exit 1
    fi
}

# Function to get stages with deployments
get_stages_with_deployments() {
    aws apigateway get-stages --rest-api-id "$API_GATEWAY_ID" --query 'item[].[stageName,deploymentId]' --output text 2>/dev/null || {
        echo "Error: Could not retrieve stages."
        exit 1
    }
}

# Function to get deployment with embedded API summary
get_deployment_with_summary() {
    local deployment_id=$1
    # Try with embed parameter first
    aws apigateway get-deployment --rest-api-id "$API_GATEWAY_ID" --deployment-id "$deployment_id" --embed 'apisummary' --output json 2>/dev/null || \
    # Fallback to regular deployment call
    aws apigateway get-deployment --rest-api-id "$API_GATEWAY_ID" --deployment-id "$deployment_id" --output json 2>/dev/null
}

# Function to list API Gateways
list_api_gateways() {
    echo "Available API Gateways:"
    aws apigateway get-rest-apis --query 'items[].[id,name]' --output table
}

# Main script
check_aws_cli

echo "Getting stages and their specific deployed resources for API Gateway: $API_GATEWAY_ID"
echo "Note: This script assumes each stage has separate API definitions"
echo

# Get stages and deployments
declare -a stages_array
declare -a deployments_array

while read -r stage deployment_id; do
    if [ -n "$stage" ]; then
        stages_array+=("$stage")
        deployments_array+=("$deployment_id")
    fi
done < <(get_stages_with_deployments)

if [ ${#stages_array[@]} -eq 0 ]; then
    echo "No stages found for API Gateway: $API_GATEWAY_ID"
    echo
    list_api_gateways
    exit 1
fi

# Filter for specific stage if requested
if [ -n "$SPECIFIC_STAGE" ]; then
    found=false
    for i in "${!stages_array[@]}"; do
        if [ "${stages_array[i]}" = "$SPECIFIC_STAGE" ]; then
            stages_array=("${stages_array[i]}")
            deployments_array=("${deployments_array[i]}")
            found=true
            break
        fi
    done
    
    if [ "$found" = false ]; then
        echo "Error: Stage '$SPECIFIC_STAGE' not found"
        echo "Available stages: ${stages_array[*]}"
        exit 1
    fi
    
    echo "Showing only stage: $SPECIFIC_STAGE"
    echo
fi

# Process each stage with its specific deployment
for i in "${!stages_array[@]}"; do
    stage="${stages_array[i]}"
    deployment_id="${deployments_array[i]}"
    
    echo "==================================="
    echo "STAGE: $stage"
    echo "==================================="
    echo
    echo "Resources and Methods:"
    
    if [ -z "$deployment_id" ] || [ "$deployment_id" = "null" ]; then
        echo "No deployment found for this stage"
        echo "---"
        echo
        continue
    fi
    
    # Get deployment details with API summary
    deployment_data=$(get_deployment_with_summary "$deployment_id")
    
    if [ -z "$deployment_data" ] || [ "$deployment_data" = "null" ]; then
        echo "Could not retrieve deployment data for deployment: $deployment_id"
        echo "---"
        echo
        continue
    fi
    
    # Try to extract apiSummary
    api_summary=$(echo "$deployment_data" | jq -r '.apiSummary // empty')
    
    if [ -n "$api_summary" ] && [ "$api_summary" != "null" ] && [ "$api_summary" != "{}" ]; then
        # Process resources from apiSummary
        echo "$api_summary" | jq -r 'to_entries[] | "\(.key)|\(.value)"' | sort | while IFS='|' read -r resource_path methods_obj; do
            if [ -n "$resource_path" ] && [ "$methods_obj" != "null" ]; then
                methods=$(echo "$methods_obj" | jq -r 'keys | join(", ")')
                if [ -n "$methods" ] && [ "$methods" != "null" ] && [ "$methods" != "" ]; then
                    echo "Path: $resource_path"
                    echo "Methods: $methods"
                    echo "---"
                fi
            fi
        done
    else
        # Fallback: show basic deployment info
        echo "Deployment ID: $deployment_id"
        description=$(echo "$deployment_data" | jq -r '.description // "No description"')
        created_date=$(echo "$deployment_data" | jq -r '.createdDate // "Unknown"')
        echo "Description: $description"
        echo "Created: $created_date"
        echo "Note: API summary not available - this deployment may not contain detailed resource information"
        echo "---"
    fi
    
    echo
done

echo "Script completed successfully!"
