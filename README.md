Here’s a `README.md` to explain how the script works, how to set it up, and how to use it:

---

# Replace and Release Elastic IP Script

This script automates the process of replacing the Elastic IP (EIP) attached to an EC2 instance with a new one and releasing the old Elastic IP to prevent unnecessary charges.

## How It Works

1. **Allocates a new Elastic IP** for the EC2 instance.
2. **Disassociates the current Elastic IP** (if there is one) from the instance.
3. **Associates the new Elastic IP** with the specified EC2 instance.
4. **Releases the old Elastic IP** so that it no longer incurs charges.

The script is particularly useful when you need to rotate Elastic IPs on your EC2 instances and want to ensure that the old ones are properly released to avoid unnecessary costs.

---

## Prerequisites

Before running the script, ensure the following:

1. You have the **AWS CLI** installed and configured on your machine.
   - [Installing the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
   - [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
   
2. Your AWS CLI configuration has sufficient permissions to:
   - Allocate Elastic IPs
   - Disassociate and associate Elastic IPs
   - Release Elastic IPs
   
   **IAM Policies Required:**
   - `ec2:AllocateAddress`
   - `ec2:DescribeAddresses`
   - `ec2:AssociateAddress`
   - `ec2:DisassociateAddress`
   - `ec2:ReleaseAddress`

---

## Script Variables

- **`INSTANCE_ID`**: The EC2 instance ID that will have its Elastic IP replaced.
- **`REGION`**: The AWS region where the instance is located (default: `us-east-1`).
- **`PROFILE`**: The AWS CLI profile to use (default: `default`).

---

## Setup

1. **Clone or download** the script.
2. **Make the script executable** by running the following command in your terminal:

   ```bash
   chmod +x replace_and_release_elastic_ip.sh
   ```

---

## Usage

Run the script by passing the EC2 instance ID as an argument:

```bash
./replace_and_release_elastic_ip.sh <instance-id>
```

Example:

```bash
./replace_and_release_elastic_ip.sh i-0a1b2c3d4e5f67890
```

### Output

- The script will output key steps during the process, such as:
  - Allocating a new Elastic IP.
  - Disassociating the old Elastic IP (if one exists).
  - Associating the new Elastic IP.
  - Releasing the old Elastic IP (if it was associated with the instance).

---

## Example Output

```bash
Allocating new Elastic IP...
New Elastic IP allocated: 52.10.20.30
Disassociating current Elastic IP...
Current Elastic IP disassociated.
Associating new Elastic IP with the instance...
New Elastic IP (52.10.20.30) associated with instance i-0a1b2c3d4e5f67890.
Releasing old Elastic IP...
Old Elastic IP released.
Operation completed successfully.
```

---

## Error Handling

- If the instance does not have an associated Elastic IP, the script will skip the disassociation and release steps.
- The script uses `set -e` to exit immediately if any command fails.

---

## License

This script is licensed under the MIT License. You are free to use, modify, and distribute it as needed.

---

## Troubleshooting

- **InvalidIPAddress.InUse**: This error occurs when trying to release an Elastic IP that is still associated with an instance. The script ensures proper disassociation before attempting to release the old Elastic IP.
- **AWS CLI Errors**: Ensure that your AWS CLI is properly configured with the correct region, profile, and permissions.

---

Feel free to modify the script to suit your specific needs!

---

This `README.md` provides a complete explanation of how to use and set up the script, along with common issues and solutions. Let me know if you need any other details!
