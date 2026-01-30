# Open Horizon Admin Utilities

The purpose of this repo is to collect scripts that will automate creation, listing, and removing of organizations, users, services, and nodes in an Open Horizon instance.

## Design Goals and Philosophy

The scripts in this repo are intended to be used by an Open Horizon administrator to manage their Open Horizon instance.  They should be able to operate in three modes:

1. Default, interactive exploration mode where they provide most of the information a person is likely to need, prompt for missing information, and link to more details, if desired.
2. Verbose mode where all of the details are listed exhaustively, where a person is trying to find specific details.
3. Minimal, programmatic mode where all of the arguments can be passed to the script and the response is machine-readable in JSON format.  This can be integrated into tools, tests, and automation.

The scripts are designed to be simple, easy to use, and require minimal setup.  They assume bash 3.x or earlier, jq, and curl.  They do not need to be run on the same machine as the Open Horizon instance.

## Project Structure

```
hzn-utils/
├── lib/
│   └── common.sh              # Shared library with common functions
├── list-orgs.sh               # Interactive organization listing (hzn CLI)
├── list-users.sh              # Interactive user listing (hzn CLI)
├── list-user.sh               # Current user info (hzn CLI)
├── list-a-orgs.sh             # API-based organization listing
├── list-a-users.sh            # API-based user listing
├── list-a-user.sh             # API-based current user info
├── can-i-list-users.sh      # Permission verification script
├── list-a-org-nodes.sh        # API-based organization node listing
├── list-a-user-nodes.sh       # API-based user node listing
├── list-a-user-services.sh    # API-based user service listing
├── list-a-user-deployment.sh  # API-based user deployment policy listing
├── test-credentials.sh        # Credential validation tool
├── test-hzn.sh                # CLI installation test
└── *.env                      # Credential files (not in git)
```

## Available Scripts

This repository contains several utility scripts for managing Open Horizon instances:

### Interactive Scripts (using hzn CLI)
- **`list-orgs.sh`** - Interactive script to list organizations and optionally view users
- **`list-users.sh`** - Interactive script to list users in an organization
- **`list-user.sh`** - Display current authenticated user info and validate credentials

### API-Based Scripts (using REST API)
- **`list-a-orgs.sh`** - List organizations using REST API with multiple output modes
- **`list-a-users.sh`** - List users using REST API with multiple output modes
- **`list-a-user.sh`** - Display current authenticated user info using REST API
- **`list-a-org-nodes.sh`** - List all nodes in an organization using REST API
- **`list-a-user-nodes.sh`** - List nodes for a specific user using REST API
- **`list-a-user-services.sh`** - List services for a specific user using REST API
- **`list-a-user-deployment.sh`** - List deployment policies for a specific user using REST API

### Permission Scripts
- **`can-i-list-users.sh`** - Check if user can list users in an organization
- **`can-i-list-orgs.sh`** - Check if user can list organizations
- **`can-i-list-services.sh`** - Check if user can list services at different access levels

### Monitoring Scripts
- **`monitor-nodes.sh`** - Real-time node monitoring utility (like 'top' for nodes)

### Testing Scripts
- **`test-credentials.sh`** - Test and validate your Open Horizon credentials
- **`test-hzn.sh`** - Test Open Horizon CLI installation and configuration
- **`run-tests.sh`** - Run the complete test suite (unit and integration tests)

## Quick Start

### Environment Setup

1. Create one or more `.env` files with your credentials:
   ```bash
   cp example.env production.env
   # Edit production.env with your actual credentials
   ```

2. Your `.env` file should contain:
   ```bash
   HZN_EXCHANGE_URL=https://open-horizon.lfedge.iol.unh.edu:3090/v1/
   HZN_ORG_ID=myorg
   HZN_EXCHANGE_USER_AUTH=myuser:mypassword
   ```

3. You can create multiple `.env` files for different environments:
   - `production.env`
   - `staging.env`
   - `development.env`
   - `mycreds.env`
   - etc.

### Basic Usage Examples

**List organizations (interactive):**
```bash
./list-orgs.sh
```

**List users (interactive):**
```bash
./list-users.sh
```

**List organizations (API, JSON output):**
```bash
./list-a-orgs.sh --json mycreds.env
```

**List nodes for a user:**
```bash
./list-a-user-nodes.sh myuser mycreds.env
```

**List all nodes in organization:**
```bash
./list-a-org-nodes.sh mycreds.env
```

**Check user permissions:**
```bash
./can-i-list-users.sh
```

**Test credentials:**
```bash
./test-credentials.sh
```

## Script Documentation

### list-orgs.sh (Interactive Organization Listing)

Interactive script that allows you to select credentials from multiple .env files and list organizations. After listing organizations, it prompts you to select one to view its users.

**Usage:**
```bash
./list-orgs.sh
```

**Features:**
- Interactive .env file selection
- Lists all organizations
- Prompts to select an organization to view users
- Automatically calls list-users.sh for the selected organization
- Color-coded output with status indicators

**Workflow:**
1. Searches for .env files in current directory
2. Prompts user to select credentials
3. Loads and validates credentials
4. Lists all organizations
5. Prompts to select an organization
6. Calls list-users.sh to display users in selected organization

### list-users.sh (Interactive User Listing)

Interactive script to list users in a specific organization. Can be called standalone or from list-orgs.sh.

**Usage:**
```bash
# Interactive mode (prompts for .env file)
./list-users.sh

# Specify organization (uses environment credentials)
./list-users.sh <org-id>

# Called from list-orgs.sh (credentials passed via environment)
# Automatically uses credentials from parent script
```

**Features:**
- Interactive .env file selection (if not called from another script)
- Lists users with email addresses
- Shows admin and hub admin status
- Can query different organization than auth organization
- Reuses credentials when called from list-orgs.sh

### list-user.sh (Current User Info - CLI)

Display information about the currently authenticated user. This validates credentials and shows user details including admin privileges.

**Usage:**
```bash
# Interactive mode (prompts for .env file)
./list-user.sh

# Use specific .env file
./list-user.sh mycreds.env
```

**Features:**
- Validates user credentials against the Exchange
- Displays user ID, email, admin status, hub admin status
- Shows last updated timestamp and who updated the user
- Color-coded admin status indicators
- Detailed error messages and troubleshooting tips

**Note:** Requires Exchange version 2.124.0 or above due to hzn CLI requirements. For older Exchange servers, use `list-a-user.sh` instead.

### list-a-user.sh (Current User Info - API)

Display information about the currently authenticated user using REST API directly. This validates credentials and shows user details including admin privileges.

**Usage:**
```bash
# Interactive mode (prompts for .env file)
./list-a-user.sh

# Use specific .env file
./list-a-user.sh mycreds.env

# JSON output only (for piping/automation)
./list-a-user.sh --json mycreds.env

# Verbose mode with full JSON details
./list-a-user.sh --verbose
```

**Options:**
- `-v, --verbose` - Show detailed JSON response
- `-j, --json` - Output raw JSON only (no colors, headers, or messages)
- `-h, --help` - Show help message

**Features:**
- Direct REST API calls using curl (works with any Exchange version)
- Multiple output modes (simple, verbose, JSON-only)
- Displays user ID, email, admin status, hub admin status
- Shows last updated timestamp and who updated the user
- Color-coded admin status indicators
- Supports self-signed certificates (common in Open Horizon deployments)
- Detailed error messages and troubleshooting tips

**User Information Displayed:**
- User ID (org/username)
- Email address
- Org Admin status (green "Yes" if admin)
- Hub Admin status (magenta "Yes" if hub admin)
- Last Updated timestamp
- Updated By (who last modified the user)

### list-a-orgs.sh (API-Based Organization Listing)

Advanced script using REST API directly with multiple output modes for automation and scripting.

**Usage:**
```bash
# Interactive mode
./list-a-orgs.sh

# Use specific .env file
./list-a-orgs.sh mycreds.env

# JSON output only (for piping/automation)
./list-a-orgs.sh --json mycreds.env

# Verbose mode with full JSON details
./list-a-orgs.sh --verbose
```

**Options:**
- `-v, --verbose` - Show detailed JSON response with headers
- `-j, --json` - Output raw JSON only (no colors, headers, or messages)
- `-h, --help` - Show help message

**Features:**
- Direct REST API calls using curl
- Multiple output modes (simple, verbose, JSON-only)
- Access permission checking for each organization
- Supports both interactive and non-interactive modes
- Detailed error messages and troubleshooting tips
- Optional jq support for better JSON parsing

**Output Modes:**
1. **Default**: Simple list of organization names
2. **Verbose** (`--verbose`): Full JSON response with formatting
3. **JSON-only** (`--json`): Raw JSON for automation/piping

### list-a-users.sh (API-Based User Listing)

Advanced script using REST API directly with multiple output modes for automation and scripting.

**Usage:**
```bash
# Interactive mode
./list-a-users.sh

# Use specific .env file
./list-a-users.sh mycreds.env

# JSON output only (for piping/automation)
./list-a-users.sh --json mycreds.env

# Verbose mode with full JSON details
./list-a-users.sh --verbose
```

**Options:**
- `-v, --verbose` - Show detailed JSON response with headers
- `-j, --json` - Output raw JSON only (no colors, headers, or messages)
- `-h, --help` - Show help message

**Features:**
- Direct REST API calls using curl
- Multiple output modes (simple, verbose, JSON-only)
- User role analysis (admin, hub admin, regular users)
- Email address display
- Color-coded role indicators
- Supports both interactive and non-interactive modes
- Optional jq support for better JSON parsing

**User Role Legend:**
- `[Org Admin]` (Yellow) - Administrative access within the organization
- `[Hub Admin]` (Magenta) - Hub-level administrative access
- (no badge) - Regular user with standard permissions

### list-a-user-nodes.sh (API-Based User Node Listing)

Advanced script using REST API directly to list nodes registered by a specific user. If no user ID is provided, it defaults to the authenticated user from the credentials.

**Usage:**
```bash
# Query nodes for authenticated user (default)
./list-a-user-nodes.sh

# Specify different user ID
./list-a-user-nodes.sh myuser

# Use specific user and .env file
./list-a-user-nodes.sh myuser mycreds.env

# JSON output for authenticated user
./list-a-user-nodes.sh --json mycreds.env

# JSON output for specific user
./list-a-user-nodes.sh --json myuser mycreds.env

# Verbose mode with full JSON details
./list-a-user-nodes.sh --verbose myuser
```

**Options:**
- `-v, --verbose` - Show detailed JSON response with headers
- `-j, --json` - Output raw JSON only (no colors, headers, or messages)
- `-h, --help` - Show help message

**Features:**
- Direct REST API calls using curl
- Multiple output modes (simple, verbose, JSON-only)
- Node status analysis (configured, unconfigured)
- Node type display (device, cluster)
- Pattern information
- Supports both interactive and non-interactive modes
- Optional jq support for better JSON parsing

**Node Status Legend:**
- `[Configured]` (Green) - Node is configured and registered
- `[Unconfigured]` (Yellow) - Node is registered but not configured
- `[Unknown]` (Red) - Node status is unknown

### list-a-org-nodes.sh (API-Based Organization Node Listing)

Advanced script using REST API directly to list all nodes in an organization.

**Usage:**
```bash
# Interactive mode
./list-a-org-nodes.sh

# Use specific .env file
./list-a-org-nodes.sh mycreds.env

# JSON output only (for piping/automation)
./list-a-org-nodes.sh --json mycreds.env

# Verbose mode with full JSON details
./list-a-org-nodes.sh --verbose
```

**Options:**
- `-v, --verbose` - Show detailed JSON response with headers
- `-j, --json` - Output raw JSON only (no colors, headers, or messages)
- `-h, --help` - Show help message

**Features:**
- Direct REST API calls using curl
- Multiple output modes (simple, verbose, JSON-only)
- Node status analysis (configured, unconfigured)
- Node type analysis (device, cluster)
- Owner tracking for each node
- Pattern information
- Summary statistics (total nodes, by status, by type, unique owners)
- Supports both interactive and non-interactive modes
- Optional jq support for better JSON parsing

**Node Status Legend:**
- `[Configured]` (Green) - Node is configured and registered
- `[Unconfigured]` (Yellow) - Node is registered but not configured
- `[Unknown]` (Red) - Node status is unknown

**Node Type Legend:**
- `[Device]` (Blue) - Edge device node
- `[Cluster]` (Magenta) - Edge cluster node

### monitor-nodes.sh (Real-Time Node Monitoring)

Real-time monitoring utility for Open Horizon nodes, similar to the `top` command. Displays a continuously updating table of nodes sorted by most recent heartbeat activity.

**Usage:**
```bash
# Monitor with default settings (10s refresh)
./monitor-nodes.sh

# Custom refresh interval (5 seconds)
./monitor-nodes.sh -i 5

# Monitor specific user's nodes
./monitor-nodes.sh -u myuser

# Run once and exit (no continuous monitoring)
./monitor-nodes.sh --once

# JSON output for automation
./monitor-nodes.sh --json mycreds.env

# Use specific .env file
./monitor-nodes.sh mycreds.env
```

**Options:**
- `-i, --interval SECONDS` - Refresh interval in seconds (default: 10)
- `-u, --user USER_ID` - Monitor nodes for specific user (default: authenticated user)
- `-n, --no-color` - Disable color output
- `-1, --once` - Run once and exit (no continuous monitoring)
- `-j, --json` - Output JSON format (implies --once)
- `-v, --verbose` - Show detailed information
- `-h, --help` - Show help message

**Features:**
- Real-time monitoring with configurable refresh interval
- Nodes sorted by most recent heartbeat (freshest at top)
- Human-readable time format (e.g., "5s ago", "2m ago", "3h ago")
- Color-coded status based on heartbeat age:
  - 🟢 Green: Active (< 2 minutes)
  - 🟡 Yellow: Stale (2-10 minutes)
  - 🔴 Red: Inactive (> 10 minutes)
- Summary statistics (total, active, stale, inactive nodes)
- Interactive controls (q to quit, r to refresh)
- Multiple output modes (interactive, once, JSON)
- Terminal-friendly display with automatic cleanup

**Display Format:**
```
═══════════════════════════════════════════════════════════════════════════════
Open Horizon Node Monitor - User: username, Org: orgname
═══════════════════════════════════════════════════════════════════════════════
Refresh: 10s | Total: 5 | Active: 2 | Stale: 1 | Inactive: 2
Last Updated: 2026-01-30 15:45:23

NODE ID                   TYPE         ARCH       STATUS   LAST HEARTBEAT       PATTERN
───────────────────────────────────────────────────────────────────────────────
node-prod-01              device       amd64      Active   5s ago               ibm.helloworld
node-prod-02              device       arm64      Active   12s ago              ibm.helloworld
node-staging-01           cluster      amd64      Stale    5m ago               ibm.cpu2evtstreams
node-dev-01               device       amd64      Inactive 2h ago               -
node-test-01              device       arm64      Inactive 5d ago               -

Press 'q' to quit, 'r' to refresh now
```

**Interactive Controls:**
- `q` or `Ctrl+C` - Exit the monitor
- `r` - Force immediate refresh (doesn't wait for interval)

**Use Cases:**
- Monitor node health and activity in real-time
- Quickly identify inactive or stale nodes
- Track node heartbeat patterns
- Verify nodes are checking in regularly
- Troubleshoot node connectivity issues
- Generate node status reports (using --once or --json)

**Node Status Determination:**
Since the Exchange API doesn't provide a `configstate` field, status is determined by heartbeat age:
- **Active**: Last heartbeat within 2 minutes
- **Stale**: Last heartbeat between 2-10 minutes
- **Inactive**: Last heartbeat older than 10 minutes

**Technical Details:**
- Uses `lastHeartbeat` field from Exchange API
- Timestamps in ISO 8601 UTC format
- Sorts nodes by heartbeat timestamp (most recent first)
- Terminal control for cursor hiding/showing
- Graceful cleanup on exit or interrupt

### can-i-list-orgs.sh (Organization Permission Verification)

Advanced script to check if the authenticated user can list organizations using three-level verification (general to specific).

**Usage:**
```bash
# Check permission interactively
./can-i-list-orgs.sh

# JSON output for automation
./can-i-list-orgs.sh --json mycreds.env

# Verbose mode for debugging
./can-i-list-orgs.sh --verbose
```

**Options:**
- `-v, --verbose` - Show detailed output with API responses
- `-j, --json` - Output JSON only (for scripting/automation)
- `-h, --help` - Show help message

**Three-Level Testing (General → Specific):**
1. **Level 1**: List ALL organizations - Hub Admin (all) or Org Admin (own)
2. **Level 2**: View auth organization details - Organization member
3. **Level 3**: View user's role in organization - Any authenticated user

**Features:**
- Progressive permission testing from broadest to narrowest scope
- Shows exactly what the user can and cannot access
- Displays scope of access (ALL orgs vs OWN org only)
- Shows user's role in the organization
- Multiple output modes (human-readable, JSON, verbose)
- API key authentication support with automatic username resolution
- Exit codes: 0 (can list orgs), 1 (cannot list), 2 (error)

### can-i-list-users.sh (User Permission Verification)

Advanced script to check if the authenticated user can list users using three-level verification (general to specific).

**Usage:**
```bash
# Check permission in auth organization
./can-i-list-users.sh

# Check permission in different organization
./can-i-list-users.sh -o other-org

# JSON output for automation
./can-i-list-users.sh --json mycreds.env

# Verbose mode for debugging
./can-i-list-users.sh --verbose
```

**Options:**
- `-o, --org ORG` - Target organization to check (default: auth org)
- `-v, --verbose` - Show detailed output with API responses
- `-j, --json` - Output JSON only (for scripting/automation)
- `-h, --help` - Show help message

**Three-Level Testing (General → Specific):**
1. **Level 1**: List ALL users (across all organizations) - Hub Admin only
2. **Level 2**: List users in target organization - Org Admin or Hub Admin
3. **Level 3**: View own user information - Any authenticated user

**Features:**
- Progressive permission testing from broadest to narrowest scope
- Shows exactly what the user can and cannot access
- Detailed troubleshooting showing where permissions break down
- Multiple output modes (human-readable, JSON, verbose)
- API key authentication support with automatic username resolution

### can-i-list-services.sh (Service Permission Verification)

Advanced script to check if the authenticated user can list services at different access levels using three-level verification (general to specific).

**Usage:**
```bash
# Check permission in auth organization
./can-i-list-services.sh

# Check permission in different organization
./can-i-list-services.sh -o other-org

# Use custom IBM organization name
./can-i-list-services.sh --ibm-org myibm

# JSON output for automation
./can-i-list-services.sh --json mycreds.env

# Verbose mode for debugging
./can-i-list-services.sh --verbose
```

**Options:**
- `-o, --org ORG` - Target organization to check (default: auth org)
- `-i, --ibm-org ORG` - IBM organization name (default: IBM)
- `-v, --verbose` - Show detailed output with API responses
- `-j, --json` - Output JSON only (for scripting/automation)
- `-h, --help` - Show help message

**Service Visibility Rules:**
- Users can list their own public and private services
- Users can list all public services in their organization
- Users can list all public services in the IBM organization
- Private services are only visible to their owner

**Three-Level Testing (General → Specific):**
1. **Level 1**: List IBM public services - Any authenticated user
2. **Level 2**: List organization's public services - Any authenticated user
3. **Level 3**: List own services (public + private) - Any authenticated user

**Features:**
- Progressive permission testing from broadest to narrowest scope
- Accurate public/private service filtering and counting
- Configurable IBM organization name
- Shows service counts at each level (total, public, private)
- Multiple output modes (human-readable, JSON, verbose)
- API key authentication support with automatic username resolution
- Exit codes: 0 (can list at all levels), 1 (cannot list at one or more levels), 2 (error)


- Exit codes: 0 (can list org users), 1 (cannot list), 2 (error)

### test-credentials.sh (Credential Testing)

Test and validate Open Horizon credentials from .env files.

**Usage:**
```bash
./test-credentials.sh
```

**Features:**
- Interactive .env file selection
- Validates all required environment variables
- Tests Exchange connectivity
- Verifies user authentication
- Checks user permissions
- Displays credential summary
- Provides detailed troubleshooting tips on failure

**Validation Checks:**
- ✓ Exchange URL is reachable
- ✓ Organization exists
- ✓ User is authenticated
- ✓ User has permission to list users
- ✓ Counts users in organization

### test-hzn.sh (CLI Testing)

Test Open Horizon CLI installation and configuration.

**Usage:**
```bash
./test-hzn.sh
```

**Features:**
- Checks if hzn CLI is installed
- Verifies CLI version
- Tests agent connectivity
- Validates node configuration
## Environment File Configuration

All scripts use `.env` files for credential management. Create one or more `.env` files with the following format:

### Username/Password Authentication
```bash
HZN_EXCHANGE_URL=https://open-horizon.lfedge.iol.unh.edu:3090/v1/
HZN_ORG_ID=myorg
HZN_EXCHANGE_USER_AUTH=myuser:mypassword
```

### API Key Authentication
```bash
HZN_EXCHANGE_URL=https://open-horizon.lfedge.iol.unh.edu:3090/v1/
HZN_ORG_ID=myorg
HZN_EXCHANGE_USER_AUTH=apikey:f47ac10b-58cc-4372-a567-0e02b2c3d479
```

**Note**: When using API key authentication, the scripts will automatically resolve the actual username by querying the Exchange API. This is particularly useful for the `can-i-list-*` permission verification scripts.

**Multiple Environment Support:**
You can create multiple `.env` files for different environments:
- `production.env`
- `staging.env`
- `development.env`
- `mycreds.env`
- etc.

**Security Note:** Never commit `.env` files to version control. Add `*.env` to `.gitignore` (except `example.env`).


## Prerequisites

### Is the CLI installed, configured, and running?

#### Installed and location
`which hzn` should tell you if the binary is installed and available.

#### Running
`hzn version` should tell you if the CLI is running.  You should receive values for both the CLI and the agent.  If the agent is not running, you will receive an error message like below:

```bash
$ hzn version
Horizon CLI version: 2.31.0-1528
Horizon Agent version: failed to get.
```

On macOS, you can try running the agent with IF docker desktop or podman desktop is installed and running:

```bash
horizon-container start
```

If that throws an error message like the following, then start Docker Desktop or Podman Desktop:

```bash
Starting the Horizon agent container openhorizon/amd64_anax:2.31.0-1528...
failed to connect to the docker API at unix:///Users/josephpearson/.docker/run/docker.sock; check if the path is correct and if the daemon is running: dial unix /Users/josephpearson/.docker/run/docker.sock: connect: no such file or directory
Error: exit code 1 from: docker run
```

IF running `horizon-contain start` results in an error message like the following, then you need to stop and restart the container:

```bash
Starting the Horizon agent container openhorizon/amd64_anax:2.31.0-1528...
docker: Error response from daemon: Conflict. The container name "/horizon1" is already in use by container "1ff9c8e008e5c9900108db92570b564efac8b2d72f08d30bf32de3502d8c7c72". You have to remove (or rename) that container to be able to reuse that name.

Run 'docker run --help' for more information
Error: exit code 125 from: docker run
```

Then `horizon-container stop` and `horizon-container start` should resolve the issue.  NOTE: Stopping the container may require you to enter your password.

When it is running properly, you should see something like the following:

```bash
% hzn version
Horizon CLI version: 2.31.0-1528
Horizon Agent version: 2.31.0-1528
```

**Note:** Version numbers shown in examples may vary based on your Open Horizon installation.

#### Configured

##### Node configured?

```bash
hzn node ls
```

Should return something like the following:

```bash
% hzn node ls
{
  "id": "joeinteel",
  "organization": null,
  "pattern": null,
  "name": null,
  "nodeType": null,
  "clusterNamespace": null,
  "token_last_valid_time": "",
  "token_valid": null,
  "ha_group": null,
  "configstate": {
    "state": "unconfigured",
    "last_update_time": ""
  },
  "configuration": {
    "exchange_api": "http://open-horizon.lfedge.iol.unh.edu:3090/v1/",
    "exchange_version": "2.110.4",
    "required_minimum_exchange_version": "2.90.1",
    "preferred_exchange_version": "2.110.1",
    "mms_api": "http://open-horizon.lfedge.iol.unh.edu:9443",
    "architecture": "amd64",
    "horizon_version": "2.31.0-1528"
  }
}
```

##### Exchange reachable and user authenticated?

```bash
hzn ex user ls
```

If you see something like the following, you do not have the proper environment variables set:

```bash
Error: organization ID must be specified with either the -o flag or HZN_ORG_ID
```

If it is properly configured and reachable, the response will be similar to the following:

```bash
{
  "examples/joewxboy": {
    "password": "********",
    "email": "joe.pearson@us.ibm.com",
    "admin": true,
    "hubAdmin": false,
    "lastUpdated": "2025-04-25T18:26:34.773362847Z[UTC]",
    "updatedBy": "root/root"
  }
}
```

Where "examples/joewxboy" is your org ID and user ID, "email" is your email address, and "admin" is true if you are an admin.

## Open Horizon CLI Operations

### Listing Organizations

**Using the hzn CLI:**
```bash
# Set required environment variables
export HZN_EXCHANGE_URL="https://<exchange-host>/api/v1"
export HZN_ORG_ID="<your-org-id>"
export HZN_EXCHANGE_USER_AUTH="<user>:<password>"

# List all organizations
hzn exchange org list

# List organizations with detailed info
hzn exchange org list -l

# List a specific organization
hzn exchange org list <org-id>
```

**Required Configuration:**
- `HZN_EXCHANGE_URL`: The Horizon Exchange API URL
- `HZN_ORG_ID`: Your organization ID
- `HZN_EXCHANGE_USER_AUTH`: User credentials in format `<user>:<password>`

**Using the REST API:**
```bash
# List all organizations
curl -u "<org>/<user>:<password>" \
  "https://<exchange-host>/api/v1/orgs"

# List only IBM-managed organizations
curl -u "<org>/<user>:<password>" \
  "https://<exchange-host>/api/v1/orgs?orgtype=IBM"
```

**Configuration File:**
You can also configure these settings in `~/.hzn/hzn.json`:
```json
{
  "HZN_EXCHANGE_URL": "https://my-exchange.example.com/api/v1",
  "HZN_ORG_ID": "myorg",
  "HZN_EXCHANGE_USER_AUTH": "myuser:mypassword"
}
```

### Other Common Operations

**Create an organization:**
```bash
hzn exchange org create --description="My Organization" myorg
```

**List users:**
```bash
hzn exchange user list
```

**List nodes:**
```bash
hzn exchange node list
```

**List services:**
```bash
hzn exchange service list
```

## Security Best Practices

- **Never commit `.env` files to version control**
- Add `*.env` to your `.gitignore` file (except `example.env`)
- Use different credentials for different environments
- Rotate credentials regularly
- Use least-privilege access for service accounts
- Store sensitive credentials securely
- Use HTTPS for all API calls
- Validate all user inputs in scripts

## Troubleshooting

### Script can't find .env files
- Ensure your `.env` files are in the same directory as the script
- Check file permissions: `ls -la *.env`
- Verify file names end with `.env` extension

### Authentication errors
- Verify credentials in your `.env` file
- Test manually: `hzn exchange user list`
- Check Exchange URL is correct and reachable
- Ensure user exists in the specified organization
- Verify password is correct (no extra spaces or special characters)

### Agent not running
- On macOS: `horizon-container start`
- Check Docker/Podman is running
- Verify with: `hzn version`
- If container conflict, try: `horizon-container stop` then `horizon-container start`

### Permission errors
- Verify your user has appropriate permissions in the organization
- Check if you're using the correct organization ID
- Contact your Open Horizon administrator for access

### API connection errors
- Verify the Exchange URL is correct and includes the API version (e.g., `/v1`)
- Check network connectivity to the Exchange server
- Ensure firewall rules allow access to the Exchange
- Test with curl: `curl -u "$HZN_ORG_ID/$USER:$PASS" "$HZN_EXCHANGE_URL/orgs"`

## Contributing

Contributions are welcome! Please follow the coding standards outlined in `AGENTS.md`.

### Development Guidelines
- Follow bash scripting best practices
- Add error handling and validation
- Include helpful error messages
- Test scripts with multiple .env files
- Document new features in both README.md and AGENTS.md
- Use consistent formatting and style

## Additional Resources

- [Open Horizon Documentation](https://open-horizon.github.io/)
- [Open Horizon GitHub](https://github.com/open-horizon)
- [Horizon CLI Reference](https://github.com/open-horizon/anax/blob/master/docs/cli.md)
- [Exchange API Documentation](https://github.com/open-horizon/exchange-api)

## Testing

This project includes a comprehensive test suite using bats-core (Bash Automated Testing System). For detailed testing information, see [TESTING.md](TESTING.md).

### Quick Start

```bash
# Install bats (macOS)
brew install bats-core

# Install bats (Linux)
sudo apt-get install bats

# Run all tests
./run-tests.sh

# Run specific test types
./run-tests.sh --unit          # Unit tests only
./run-tests.sh --integration   # Integration tests only
./run-tests.sh --shellcheck    # Static analysis only
```

### Test Structure

- **Unit Tests** (`tests/unit/`): Test individual functions in `lib/common.sh`
- **Integration Tests** (`tests/integration/`): Test complete scripts end-to-end
- **Fixtures** (`tests/fixtures/`): Test data and mock credential files
- **CI/CD** (`.github/workflows/test.yml`): Automated testing on push and PR

### Writing Tests

See [TESTING.md](TESTING.md) for comprehensive documentation on:
- Writing new tests
- Test best practices
- Using test helpers
- Debugging test failures
- Contributing test coverage
