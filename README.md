# MySQL RDS Dump & Restore Script

A Bash script for migrating MySQL databases between RDS instances (or any MySQL hosts) with user creation capabilities.

## 📋 Overview

This script automates the process of:
- Dumping a database from a source MySQL host
- Creating the target database (if it doesn't exist)
- Restoring the database to a target MySQL host
- Optionally creating and configuring a database user with appropriate permissions

## 🚀 Features

- Secure password handling (with optional interactive prompts)
- Comprehensive database dump with routines and table structures
- Conditional user creation with granular permissions
- Error handling with immediate exit on failure
- Execution time tracking
- Interactive confirmation before proceeding

## ⚙️ Configuration Variables

Edit these variables in the script before execution:

| Variable | Description | Example |
|----------|-------------|---------|
| `admin_user_host_from` | Admin username for source host | `admin` |
| `admin_pass_host_from` | Admin password for source host (empty to prompt) | `""` |
| `admin_user_host_to` | Admin username for target host | `admin` |
| `admin_pass_host_to` | Admin password for target host (empty to prompt) | `""` |
| `db_name` | Database name to migrate | `api-name` |
| `host_from` | Source MySQL hostname/IP | `host-a` |
| `host_to` | Target MySQL hostname/IP | `host-b` |
| `create_user` | Whether to create database user | `true`/`false` |
| `db_user` | Database username to create | `api-name` |
| `db_pass` | Database user password | `my-secret-password` |

## 📁 Generated Files

The script creates dump files with timestamp format: `{db_name}-{YYYYMMDD-HHMMSS}.sql`

## 🛠️ Prerequisites

- Bash shell
- MySQL client tools (`mysqldump`, `mysql`)
- Network access to both MySQL hosts
- Admin privileges on both MySQL instances

## 🚀 Usage

1. **Edit the configuration section** with your specific values
2. **Make the script executable**:
   ```bash
   chmod +x rds_dump_restore.sh
   ```
3. **Run the script**:
   ```bash
   ./rds_dump_restore.sh
   ```
4. **Enter passwords** when prompted (if not configured in script)

## 🔐 Security Notes

- Passwords can be set in the script or entered interactively
- Interactive mode is more secure as passwords won't be stored
- Dump files contain database contents - handle with appropriate security measures
- Ensure proper file permissions on the script and generated dump files

## ⚠️ Important Considerations

- The script uses `set -euo pipefail` for strict error handling
- GTID purging is disabled (`--set-gtid-purged=OFF`) for compatibility
- Table locks are skipped during dump (`--skip-lock-tables`)
- The user creation includes comprehensive but restrictive permissions
- Test the script in a non-production environment first

## 📝 Permission Granularity

When creating users, the script grants these permissions:
- Database structure: ALTER, CREATE, DROP, INDEX, REFERENCES
- Data manipulation: SELECT, INSERT, UPDATE, DELETE
- Advanced features: CREATE VIEW, SHOW VIEW, TRIGGER
- Stored procedures: ALTER ROUTINE, CREATE ROUTINE, EXECUTE
- Administrative: CREATE TEMPORARY TABLES, LOCK TABLES

## 🆘 Troubleshooting

- Ensure network connectivity to both MySQL hosts
- Verify admin credentials have sufficient privileges
- Check that the target database doesn't have conflicts
- Confirm available disk space for dump files
- Review MySQL error logs for detailed issues

## 📄 License

This script is provided as-is without warranty. Always test in a development environment before using in production.

---

**Note**: Always backup your databases before running migration scripts and verify the success of operations in a test environment.
