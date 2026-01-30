# Monitor Nodes Script - Design Plan

## Overview
Create a `monitor-nodes.sh` script that functions like the `top` utility, displaying real-time information about the authenticated user's registered Open Horizon nodes.

## Research Phase

### 1. Node API Response Structure
Need to investigate what data is available from the Exchange API for nodes:

**Known Fields (from list-a-user-nodes.sh):**
- `configstate.state` - Configuration state (configured/unconfigured)
- `pattern` - Deployment pattern
- `nodeType` - Type of node (device/cluster)
- `arch` - Architecture (amd64, arm64, etc.)
- `registeredServices` - Array of registered services

**Fields to Research:**
- `lastHeartbeat` or `heartbeat` - Timestamp of last communication
- `lastUpdated` - Last update timestamp
- `msgEndPoint` - Message endpoint status
- `softwareVersions` - Software version information
- `publicKey` - Node public key
- `token_last_valid_time` - Token validation timestamp
- `token_valid` - Token validity status
- Any other time-related fields that could indicate node activity

**API Endpoint:**
```
GET /orgs/{orgid}/nodes?owner={org/userid}
```

**Action Items:**
1. Make a test API call to examine the full JSON response structure
2. Identify all timestamp fields available
3. Determine which field best represents "last activity" or "heartbeat"
4. Document the complete node object schema

### 2. Heartbeat/Activity Tracking
**Questions to Answer:**
- Does the Exchange API provide a `lastHeartbeat` field?
- If not, what field indicates the most recent node activity?
- How frequently do nodes update their status?
- What does it mean when a node hasn't sent a heartbeat recently?

**Fallback Options if No Heartbeat Field:**
- Use `lastUpdated` timestamp
- Use `token_last_valid_time`
- Use `configstate.last_update_time`
- Combine multiple timestamps to determine "freshness"

## Design Specifications

### 3. User Interface Design

**Display Layout (similar to `top`):**
```
Open Horizon Node Monitor - User: username, Org: orgname
Refresh: 10s | Total Nodes: 5 | Configured: 4 | Unconfigured: 1
Last Updated: 2026-01-30 15:45:23

NODE ID              STATUS        TYPE      ARCH    LAST HEARTBEAT       PATTERN
─────────────────────────────────────────────────────────────────────────────────
node-prod-01         Configured    device    amd64   2s ago              ibm.helloworld
node-prod-02         Configured    device    arm64   5s ago              ibm.helloworld
node-staging-01      Configured    cluster   amd64   12s ago             ibm.cpu2evtstreams
node-dev-01          Unconfigured  device    amd64   2m ago              -
node-test-01         Configured    device    amd64   5m ago              ibm.helloworld

Press 'q' to quit, 'r' to refresh now, 'h' for help
```

**Key Features:**
- Header with summary statistics
- Table sorted by most recent heartbeat (freshest at top)
- Human-readable time format (e.g., "2s ago", "5m ago", "2h ago")
- Color coding for status and age
- Real-time updates every N seconds (default 10)
- Keyboard controls for interaction

### 4. Color Coding Scheme

**Status Colors:**
- Green: Configured and active (heartbeat < 1 minute)
- Yellow: Configured but stale (heartbeat 1-5 minutes)
- Red: Configured but very stale (heartbeat > 5 minutes)
- Gray: Unconfigured

**Heartbeat Age Colors:**
- Green: < 30 seconds
- Yellow: 30 seconds - 2 minutes
- Orange: 2-5 minutes
- Red: > 5 minutes

### 5. Command Line Options

```bash
./monitor-nodes.sh [OPTIONS] [ENV_FILE]

Options:
  -i, --interval SECONDS   Refresh interval in seconds (default: 10)
  -u, --user USER_ID       Monitor nodes for specific user (default: authenticated user)
  -o, --org ORG_ID         Override organization ID
  -n, --no-color           Disable color output
  -1, --once               Run once and exit (no continuous monitoring)
  -j, --json               Output JSON format (implies --once)
  -v, --verbose            Show detailed information
  -h, --help               Show help message

Examples:
  ./monitor-nodes.sh                    # Monitor with defaults (10s refresh)
  ./monitor-nodes.sh -i 5               # Refresh every 5 seconds
  ./monitor-nodes.sh -u myuser          # Monitor specific user's nodes
  ./monitor-nodes.sh --once             # Run once and exit
  ./monitor-nodes.sh --json mycreds.env # JSON output for automation
```

### 6. Technical Implementation

**Core Components:**

1. **Initialization:**
   - Parse command line arguments
   - Load credentials from .env file
   - Validate configuration
   - Set up terminal for interactive mode

2. **Data Fetching:**
   - Make API call to get nodes
   - Parse JSON response
   - Extract relevant fields
   - Calculate time differences for heartbeats

3. **Data Processing:**
   - Sort nodes by heartbeat timestamp (most recent first)
   - Format timestamps as human-readable relative times
   - Calculate summary statistics
   - Apply color coding based on age/status

4. **Display Loop:**
   - Clear screen (in interactive mode)
   - Display header with statistics
   - Display table with node information
   - Show footer with controls
   - Sleep for interval duration
   - Repeat

5. **Keyboard Handling:**
   - 'q' or Ctrl+C: Exit gracefully
   - 'r': Force immediate refresh
   - 'h': Show help overlay
   - '+'/'-': Increase/decrease refresh interval

**Terminal Control:**
```bash
# Clear screen
clear

# Hide cursor
tput civis

# Show cursor on exit
tput cnorm

# Get terminal dimensions
COLUMNS=$(tput cols)
LINES=$(tput lines)
```

**Time Formatting Function:**
```bash
format_time_ago() {
    local timestamp="$1"
    local now=$(date +%s)
    local then=$(date -d "$timestamp" +%s 2>/dev/null || echo "0")
    local diff=$((now - then))
    
    if [ $diff -lt 60 ]; then
        echo "${diff}s ago"
    elif [ $diff -lt 3600 ]; then
        echo "$((diff / 60))m ago"
    elif [ $diff -lt 86400 ]; then
        echo "$((diff / 3600))h ago"
    else
        echo "$((diff / 86400))d ago"
    fi
}
```

### 7. Error Handling

**Scenarios to Handle:**
- No nodes found for user
- API connection failures
- Invalid credentials
- Terminal too small for display
- Interrupted during refresh
- Invalid timestamp formats

**Graceful Degradation:**
- If heartbeat field not available, use alternative timestamp
- If terminal too small, show simplified view
- If API fails, show last known state with warning
- Always restore terminal state on exit

### 8. Testing Strategy

**Unit Tests:**
- Time formatting function
- Timestamp parsing
- Sorting logic
- Color code selection

**Integration Tests:**
- API call with valid credentials
- API call with invalid credentials
- Handling empty node list
- Handling malformed API responses

**Manual Tests:**
- Run with different refresh intervals
- Test keyboard controls
- Test with different terminal sizes
- Test with nodes in different states
- Test graceful exit (Ctrl+C)

## Implementation Phases

### Phase 1: Research & Validation ✓ (Current)
- [x] Review existing node listing script
- [ ] Make test API call to examine full response
- [ ] Document available timestamp fields
- [ ] Determine best field for "heartbeat"

### Phase 2: Core Script Structure
- [ ] Create script skeleton with argument parsing
- [ ] Implement credential loading
- [ ] Add basic API call functionality
- [ ] Implement single-run mode (--once)

### Phase 3: Data Processing
- [ ] Parse node data from API response
- [ ] Implement timestamp parsing and formatting
- [ ] Add sorting by heartbeat/timestamp
- [ ] Calculate summary statistics

### Phase 4: Display Implementation
- [ ] Implement table formatting
- [ ] Add color coding
- [ ] Create header and footer
- [ ] Handle terminal size constraints

### Phase 5: Interactive Mode
- [ ] Implement refresh loop
- [ ] Add keyboard input handling
- [ ] Implement terminal control (clear, cursor)
- [ ] Add graceful exit handling

### Phase 6: Polish & Testing
- [ ] Add verbose mode
- [ ] Add JSON output mode
- [ ] Implement error handling
- [ ] Write tests
- [ ] Update documentation

## Open Questions

1. **Heartbeat Field Availability:**
   - Does the Exchange API provide a `lastHeartbeat` field?
   - If not, what's the best alternative?
   - How do we handle nodes that have never sent a heartbeat?

2. **Refresh Rate:**
   - What's a reasonable default refresh interval?
   - Should we warn if interval is too short?
   - Should we implement exponential backoff on errors?

3. **Terminal Compatibility:**
   - Should we support non-interactive terminals?
   - How do we handle terminals without color support?
   - What's the minimum terminal size we should support?

4. **Performance:**
   - How many nodes can we reasonably display?
   - Should we implement pagination for large node lists?
   - Should we cache results between refreshes?

## Next Steps

1. **Immediate:** Make a test API call to examine the actual node response structure
2. **Then:** Create a prototype script with basic functionality
3. **Finally:** Iterate on the design based on actual API behavior

## References

- Existing script: `list-a-user-nodes.sh`
- Common library: `lib/common.sh`
- Open Horizon Exchange API documentation
- Similar utilities: `top`, `htop`, `watch`
