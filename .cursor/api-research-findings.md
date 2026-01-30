# Node API Research Findings

## API Endpoint
```
GET /orgs/{orgid}/nodes?owner={org/userid}
```

## Complete Node Object Schema

Based on actual API response from Open Horizon Exchange:

```json
{
  "nodes": {
    "examples/node-id": {
      "token": "********",
      "name": "node-id",
      "owner": "examples/username",
      "nodeType": "device",
      "pattern": "",
      "registeredServices": [],
      "userInput": [],
      "msgEndPoint": "",
      "softwareVersions": {
        "certificate": "",
        "config": "",
        "horizon": "2.31.0-1528"
      },
      "lastHeartbeat": "2026-01-21T20:43:29.630950821Z[UTC]",
      "publicKey": "...",
      "arch": "arm64",
      "heartbeatIntervals": {
        "minInterval": 0,
        "maxInterval": 0,
        "intervalAdjustment": 0
      },
      "ha_group": null,
      "lastUpdated": "2026-01-21T20:43:45.431694153Z[UTC]",
      "clusterNamespace": "",
      "isNamespaceScoped": false
    }
  },
  "lastIndex": 0
}
```

## Key Findings for Monitoring

### ✅ Heartbeat Field Available
- **Field Name:** `lastHeartbeat`
- **Format:** ISO 8601 UTC timestamp with nanosecond precision
- **Example:** `"2026-01-21T20:43:29.630950821Z[UTC]"`
- **Always Present:** Yes (observed in all test nodes)

### Timestamp Fields Available
1. **`lastHeartbeat`** - Primary field for monitoring node activity
2. **`lastUpdated`** - Last time node record was updated
3. Both use identical ISO 8601 format with UTC timezone

### Other Useful Fields
- **`name`** - Node identifier (without org prefix)
- **`nodeType`** - "device" or "cluster"
- **`arch`** - Architecture (arm64, amd64, etc.)
- **`pattern`** - Deployment pattern (empty string if none)
- **`registeredServices`** - Array of services (empty if none)
- **`softwareVersions.horizon`** - Horizon agent version
- **`owner`** - Full owner identifier (org/user format)

### Configuration State
**Note:** The `configstate` field is NOT present in the API response. The existing `list-a-user-nodes.sh` script checks for it but it doesn't exist in the actual data.

**Alternative Status Indicators:**
- Presence of `pattern` (non-empty = likely configured)
- Presence of `registeredServices` (non-empty = has services)
- Freshness of `lastHeartbeat` (recent = active)

## Implementation Decisions

### Primary Sorting Field
✅ Use `lastHeartbeat` for sorting (most recent first)

### Status Determination
Since `configstate` is not available, determine status by:
1. **Active:** `lastHeartbeat` within last 2 minutes
2. **Stale:** `lastHeartbeat` between 2-10 minutes
3. **Inactive:** `lastHeartbeat` older than 10 minutes
4. **Has Pattern:** Non-empty `pattern` field
5. **Has Services:** Non-empty `registeredServices` array

### Time Formatting
Convert ISO 8601 timestamps to human-readable relative time:
- "5s ago" - Less than 1 minute
- "2m ago" - Less than 1 hour
- "3h ago" - Less than 1 day
- "5d ago" - 1 day or more

### Color Coding
Based on heartbeat age:
- 🟢 Green: < 2 minutes (active)
- 🟡 Yellow: 2-10 minutes (stale)
- 🔴 Red: > 10 minutes (inactive)

## Sample Data for Testing

### Node 1: Recent Activity
```
Name: rpi5rw
Last Heartbeat: 2026-01-21T20:43:29.630950821Z
Status: Active (9 days ago from 2026-01-30)
```

### Node 2: Old Activity
```
Name: joemacbm2
Last Heartbeat: 2025-10-03T20:50:08.369130828Z
Status: Inactive (119 days ago)
```

### Node 3: Very Old Activity
```
Name: creative-canvasback
Last Heartbeat: 2025-05-28T14:38:10.146721843Z
Status: Inactive (247 days ago)
```

## Conclusion

✅ **All required data is available** for implementing the monitoring script:
- Heartbeat timestamps exist and are reliable
- Timestamp format is consistent and parseable
- All necessary node metadata is present
- No blockers for implementation

**Next Step:** Proceed with script implementation using `lastHeartbeat` as the primary monitoring field.
