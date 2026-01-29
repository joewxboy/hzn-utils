# Refactor Plan: can-i-*.sh Scripts - General to Specific Approach

## Current Behavior

### can-i-list-users.sh
- **Phase 1**: Predictive check based on user's admin/hubAdmin status
- **Phase 2**: Attempts to list users in target organization
- **Phase 3**: Compares predicted vs actual results

**Problem**: Only tests one level (target org users), doesn't show the full permission scope.

### can-i-list-orgs.sh
- **Phase 1**: Predictive check based on user's admin/hubAdmin status
- **Phase 2**: Attempts to list all organizations
- **Phase 3**: Compares predicted vs actual results

**Problem**: Only tests one level (all orgs), doesn't show org-specific or user-specific access.

## New Approach: Three-Level Testing

### Principle: General → Specific
Test permissions from broadest to narrowest scope, showing exactly what the user can access.

## can-i-list-users.sh Refactor

### Level 1: List ALL Users (Hub Admin Only)
**Endpoint**: `GET /admin/users` or iterate through all orgs
**Permission Required**: Hub Admin
**Purpose**: Test if user can see users across ALL organizations

### Level 2: List Users in Auth Organization
**Endpoint**: `GET /orgs/{HZN_ORG_ID}/users`
**Permission Required**: Org Admin or Hub Admin
**Purpose**: Test if user can see users in their own organization

### Level 3: View Specific User (Self)
**Endpoint**: `GET /orgs/{HZN_ORG_ID}/users/{AUTH_USER}`
**Permission Required**: Any authenticated user (self-access)
**Purpose**: Test if user can at least see their own information

### Output Format
```
Permission Check: Can I List Users?
═══════════════════════════════════════════════════════════════

Configuration:
  Exchange URL:      https://example.com/v1
  Auth Organization: myorg
  Auth User:         john.doe

User Permissions:
  Org Admin:  false
  Hub Admin:  false

Testing Access Levels (General → Specific):
═══════════════════════════════════════════════════════════════

Level 1: List ALL Users (across all organizations)
  Predicted: NO - User is not a Hub Admin
  Actual:    NO - HTTP 403 (forbidden)
  Status:    ✓ CONFIRMED

Level 2: List Users in Organization 'myorg'
  Predicted: NO - User is not an Org Admin
  Actual:    NO - HTTP 403 (forbidden)
  Status:    ✓ CONFIRMED

Level 3: View Own User Information
  Predicted: YES - All users can view their own info
  Actual:    YES - HTTP 200 (success)
  Status:    ✓ CONFIRMED

Result
═══════════════════════════════════════════════════════════════
✓ Permission correctly denied - user cannot list users
✓ User can access their own information

Summary:
  Can list ALL users:     NO
  Can list org users:     NO
  Can view own info:      YES
```

## can-i-list-orgs.sh Refactor

### Level 1: List ALL Organizations
**Endpoint**: `GET /orgs`
**Permission Required**: Hub Admin (sees all) or Org Admin (sees own)
**Purpose**: Test if user can see all organizations

### Level 2: View Auth Organization Details
**Endpoint**: `GET /orgs/{HZN_ORG_ID}`
**Permission Required**: Member of the organization
**Purpose**: Test if user can see their own organization details

### Level 3: View User's Role in Organization
**Endpoint**: `GET /orgs/{HZN_ORG_ID}/users/{AUTH_USER}`
**Permission Required**: Any authenticated user (self-access)
**Purpose**: Test if user can see their role/permissions in the org

### Output Format
```
Permission Check: Can I List Organizations?
═══════════════════════════════════════════════════════════════

Configuration:
  Exchange URL:      https://example.com/v1
  Auth Organization: myorg
  Auth User:         john.doe

User Permissions:
  Org Admin:  true
  Hub Admin:  false

Testing Access Levels (General → Specific):
═══════════════════════════════════════════════════════════════

Level 1: List ALL Organizations
  Predicted: YES (OWN) - User is an Org Admin (can see own org only)
  Actual:    YES (OWN) - HTTP 200 (returned 1 organization)
  Status:    ✓ CONFIRMED
  Organizations: myorg

Level 2: View Organization 'myorg' Details
  Predicted: YES - User is a member of this organization
  Actual:    YES - HTTP 200 (success)
  Status:    ✓ CONFIRMED

Level 3: View User's Role in 'myorg'
  Predicted: YES - All users can view their own info
  Actual:    YES - HTTP 200 (admin: true, hubAdmin: false)
  Status:    ✓ CONFIRMED

Result
═══════════════════════════════════════════════════════════════
✓ Permission confirmed - user can list organizations (own org only)
✓ User has Org Admin role in 'myorg'

Summary:
  Can list ALL orgs:      YES (own org only)
  Can view org details:   YES
  Role in organization:   Org Admin
```

## Implementation Strategy

### Phase 1: Update can-i-list-users.sh
1. Keep existing Phase 1 (user info fetch)
2. Replace Phase 2 with three-level testing
3. Update Phase 3 to report all three levels
4. Add summary showing highest access level achieved

### Phase 2: Update can-i-list-orgs.sh
1. Keep existing Phase 1 (user info fetch)
2. Replace Phase 2 with three-level testing
3. Update Phase 3 to report all three levels
4. Add summary showing scope of org access

### Phase 3: Add Helper Functions to lib/common.sh
```bash
# Test API endpoint and return result
test_api_access() {
    local endpoint="$1"
    local description="$2"
    # Returns: http_code, response_body, can_access (true/false)
}

# Format level test result
format_level_result() {
    local level="$1"
    local description="$2"
    local predicted="$3"
    local actual="$4"
    local status="$5"
    # Outputs formatted result with colors
}
```

### Phase 4: Maintain Backward Compatibility
- Keep existing command-line options
- Keep JSON output format (extend with new fields)
- Keep exit codes (0=can access, 1=cannot, 2=error)
- Exit code based on Level 2 (org-level access) for backward compatibility

## Benefits

1. **Clearer Permission Scope**: Users see exactly what they can and cannot access
2. **Better Troubleshooting**: Progressive testing shows where permissions break down
3. **Educational**: Users learn the permission hierarchy
4. **Comprehensive**: Tests all relevant access levels, not just one
5. **Maintains Compatibility**: Existing scripts using these tools continue to work

## Testing Requirements

1. Test with Hub Admin credentials (should pass all levels)
2. Test with Org Admin credentials (should pass org and user levels)
3. Test with regular user credentials (should pass only user level)
4. Test with API key authentication (should work at all levels)
5. Verify JSON output includes all three levels
6. Verify exit codes remain consistent

## Documentation Updates

1. Update README.md with new output examples
2. Update AGENTS.md with technical implementation details
3. Update inline help text in scripts
4. Add examples showing different permission scenarios
