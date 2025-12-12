# Replace Elastic IP Script

A Bash script to safely replace an Elastic IP address associated with an AWS EC2 instance with a new one.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Script Details](#script-details)
- [Example](#example)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Overview

This script automates the process of replacing an Elastic IP address attached to an AWS EC2 instance. It allocates a new Elastic IP, associates it with the specified instance, and releases the old Elastic IP, ensuring minimal downtime and proper cleanup.

## Prerequisites

- AWS CLI installed and configured
- Appropriate IAM permissions for the AWS account/profile:
  - `ec2:DescribeAddresses`
  - `ec2:AllocateAddress`
  - `ec2:AssociateAddress`
  - `ec2:DisassociateAddress`
  - `ec2:ReleaseAddress`
- Bash shell environment

## Installation

1. Clone or download the script to your local machine:

   ```bash
   # Option 1: Direct download
   curl -O https://path/to/replace-elastic-ip.sh
   chmod +x replace-elastic-ip.sh

   # Option 2: Clone repository (if available)
   git clone <repository-url>
   cd <repository-directory>
   chmod +x replace-elastic-ip.sh
   ```

2. Ensure the script has execute permissions:

   ```bash
   chmod +x replace-elastic-ip.sh
   ```

## Usage

### Basic Usage

```bash
./replace-elastic-ip.sh <instance-id>
```

### Parameters

- `<instance-id>`: The ID of the EC2 instance whose Elastic IP you want to replace (required)

### Example

```bash
./replace-elastic-ip.sh i-0abcdef1234567890
```

### Customizing AWS Settings

You can modify the script variables directly:

```bash
# Edit these variables in the script:
REGION="us-east-1"        # Change to your preferred AWS region
PROFILE="default"         # Change to your AWS CLI profile name
```

## Features

- **Safe Replacement**: Allocates new Elastic IP before disassociating the old one
- **Automatic Cleanup**: Releases the old Elastic IP after successful association
- **Error Handling**: Uses `set -e` to exit on errors and includes validation checks
- **No Downtime**: Minimizes service interruption during IP transition
- **AWS Profile Support**: Works with multiple AWS CLI profiles
- **Region Flexibility**: Configurable for any AWS region

## Script Details

The script performs the following steps:

1. **Validation**: Checks if the instance ID is provided
2. **Discovery**: Identifies current Elastic IP allocation and association IDs
3. **Allocation**: Creates a new Elastic IP address
4. **Disassociation**: Removes the old Elastic IP from the instance (if exists)
5. **Association**: Attaches the new Elastic IP to the instance
6. **Cleanup**: Releases the old Elastic IP (if exists)

## Example

```bash
$ ./replace-elastic-ip.sh i-0abcdef1234567890
Allocating new Elastic IP...
New Elastic IP allocated: 54.123.45.67
Disassociating current Elastic IP...
Current Elastic IP disassociated.
Associating new Elastic IP with the instance...
New Elastic IP (54.123.45.67) associated with instance i-0abcdef1234567890.
Releasing old Elastic IP...
Old Elastic IP released.
Operation completed successfully.
```

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your AWS CLI profile has the required permissions
2. **Invalid Instance ID**: Verify the instance exists and is in the correct region
3. **Rate Limiting**: AWS may throttle requests if run repeatedly
4. **Quota Exceeded**: Check your Elastic IP quota in AWS

### Debug Mode

Add `set -x` at the beginning of the script to see detailed execution:

```bash
#!/bin/bash
set -e
set -x  # Add this line for debugging
```

### Checking AWS Configuration

```bash
aws configure list --profile default
aws ec2 describe-instances --instance-ids i-0abcdef1234567890 --region us-east-1
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

**Disclaimer**: This script manages AWS resources that may incur charges. Ensure you understand AWS pricing for Elastic IPs before use. The authors are not responsible for any costs incurred through the use of this script.
