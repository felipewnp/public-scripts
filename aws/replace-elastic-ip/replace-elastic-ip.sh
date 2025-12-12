#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
INSTANCE_ID=$1  # Pass the EC2 instance ID as an argument to the script
REGION="us-east-1"  # Specify your AWS region
PROFILE="default"  # Specify the AWS CLI profile (optional, remove if not needed)

if [ -z "$INSTANCE_ID" ]; then
    echo "Usage: $0 <instance-id>"
    exit 1
fi

# Step 1: Get the current Elastic IP's Allocation ID and Association ID (if any) associated with the EC2 instance
CURRENT_ALLOCATION_ID=$(aws ec2 describe-addresses --region $REGION --query "Addresses[?InstanceId=='$INSTANCE_ID'].AllocationId" --output text --profile $PROFILE)
CURRENT_ASSOCIATION_ID=$(aws ec2 describe-addresses --region $REGION --query "Addresses[?InstanceId=='$INSTANCE_ID'].AssociationId" --output text --profile $PROFILE)

# Step 2: Allocate a new Elastic IP
echo "Allocating new Elastic IP..."
NEW_ALLOCATION_ID=$(aws ec2 allocate-address --region $REGION --query 'AllocationId' --output text --profile $PROFILE)
NEW_ELASTIC_IP=$(aws ec2 describe-addresses --allocation-ids $NEW_ALLOCATION_ID --query 'Addresses[0].PublicIp' --output text --profile $PROFILE)
echo "New Elastic IP allocated: $NEW_ELASTIC_IP"

# Step 3: Disassociate the current Elastic IP from the instance (if one exists)
if [ "$CURRENT_ASSOCIATION_ID" != "None" ] && [ -n "$CURRENT_ASSOCIATION_ID" ]; then
    echo "Disassociating current Elastic IP..."
    aws ec2 disassociate-address --association-id $CURRENT_ASSOCIATION_ID --region $REGION --profile $PROFILE
    echo "Current Elastic IP disassociated."
else
    echo "No current Elastic IP associated with the instance."
fi

# Step 4: Associate the new Elastic IP with the instance, suppressing output
echo "Associating new Elastic IP with the instance..."
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $NEW_ALLOCATION_ID --region $REGION --profile $PROFILE > /dev/null
echo "New Elastic IP ($NEW_ELASTIC_IP) associated with instance $INSTANCE_ID."

# Step 5: Release the old Elastic IP (if there was one)
if [ "$CURRENT_ALLOCATION_ID" != "None" ] && [ -n "$CURRENT_ALLOCATION_ID" ]; then
    echo "Releasing old Elastic IP..."
    aws ec2 release-address --allocation-id $CURRENT_ALLOCATION_ID --region $REGION --profile $PROFILE
    echo "Old Elastic IP released."
else
    echo "No old Elastic IP to release."
fi

echo "Operation completed successfully."
