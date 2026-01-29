# Scratchpad - hzn-utils Project Roadmap

## Project Overview

The hzn-utils project is a comprehensive collection of bash scripts for managing Open Horizon instances. It provides three operation modes:
1. **Default**: Interactive exploration with prompts and helpful output
2. **Verbose**: Exhaustive details for troubleshooting (`--verbose`)
3. **Minimal**: Machine-readable JSON for automation (`--json`)

## Current Project Status

### Completed Improvements ✅

1. **Error Handling Enhancement** (Item #2)
   - All scripts now use `set -euo pipefail` for strict error handling
   - Trap handlers implemented for cleanup
   - Comprehensive error messages with troubleshooting tips

2. **Testing Infrastructure** (Item #4)
   - Complete test suite with bats-core
   - Unit tests for `lib/common.sh` functions
   - Integration tests for all scripts
   - GitHub Actions CI/CD pipeline
   - Test runner script (`run-tests.sh`)
   - Comprehensive TESTING.md documentation

3. **Documentation Cleanup**
   - Removed redundant files
   - Created comprehensive ROADMAP.md
   - Updated README.md and AGENTS.md with all features

4. **API Key Authentication Support**
   - Automatic username resolution from API keys
   - Implemented in all permission verification scripts
   - Documented in README.md

### Recent Completed Work

#### Issue #5: Add list-user.sh script (COMPLETED)
**Status:** ✅ Merged
- **Issue:** https://github.com/joewxboy/hzn-utils/issues/5
- **PR:** https://github.com/joewxboy/hzn-utils/pull/6
- **Commit:** `9274d72`

**Scripts created:**
- `list-user.sh` - CLI-based (requires Exchange 2.124.0+)
- `list-a-user.sh` - API-based (works with any Exchange version)

**Key features:**
- Display current authenticated user information
- Show admin privileges (org admin, hub admin)
- Multiple output modes (simple, verbose, JSON-only)
- Comprehensive error handling and troubleshooting

## Detailed Roadmap

### HIGH PRIORITY

#### Item #1: Create Shared Library (CRITICAL)
**Status:** 🔴 Not Started
**Priority:** HIGH
**Effort:** Medium (2-3 days)

**Problem:** Significant code duplication across all scripts for:
- Environment file selection and loading
- Credential parsing and validation
- Print functions (colored output)
- API authentication
- Error handling patterns

**Solution:** Expand `lib/common.sh` with reusable functions:

```bash
# lib/common.sh additions needed:
- load_credentials()      # Load and validate .env files
- parse_auth()           # Parse authentication credentials
- select_env_file()      # Interactive .env file selection
- validate_url()         # URL format validation
- validate_org_id()      # Organization ID validation
- test_api_access()      # Test API endpoint accessibility
- count_json_items()     # Count items in JSON response
```

**Benefits:**
- Reduce maintenance burden by 60-70%
- Ensure consistency across all scripts
- Easier to add new features
- Centralized bug fixes

**Implementation Steps:**
1. Audit all scripts for common code patterns
2. Extract functions to `lib/common.sh`
3. Update all scripts to source common library
4. Add unit tests for new functions
5. Update documentation

---

### MEDIUM PRIORITY

#### Item #3: Add Input Validation
**Status:** 🟡 Partially Implemented
**Priority:** MEDIUM
**Effort:** Small (1-2 days)

**Current State:** Basic validation exists but inconsistent

**Needed Validations:**
- URL format validation (protocol, path structure)
- Organization ID format (alphanumeric, hyphens, underscores)
- User ID format
- API response validation (check for expected fields)
- Credential format validation

**Implementation:**
```bash
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        print_error "Invalid URL format: $url"
        return 1
    fi
    return 0
}

validate_org_id() {
    local org="$1"
    if [[ ! "$org" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid organization ID: $org"
        return 1
    fi
    return 0
}

validate_json_response() {
    local response="$1"
    local required_field="$2"
    if ! echo "$response" | jq -e ".$required_field" > /dev/null 2>&1; then
        print_error "Invalid API response: missing $required_field"
        return 1
    fi
    return 0
}
```

---

#### Item #5: Configuration Management
**Status:** 🔴 Not Started
**Priority:** MEDIUM
**Effort:** Medium (2-3 days)

**Problem:** No centralized configuration for:
- API timeouts
- Retry counts
- Default values
- Feature flags

**Solution:** Create `config/defaults.conf`:

```bash
# config/defaults.conf
DEFAULT_TIMEOUT=30
DEFAULT_RETRY_COUNT=3
API_VERSION="v1"
MAX_RESULTS_PER_PAGE=100
ENABLE_COLOR_OUTPUT=true
ENABLE_LOGGING=false
LOG_LEVEL="INFO"
```

**Implementation:**
- Create config directory structure
- Add config loading to `lib/common.sh`
- Support user overrides via `~/.hzn-utils/config`
- Document configuration options

---

#### Item #9: Security Enhancements
**Status:** 🟡 Partially Implemented
**Priority:** MEDIUM
**Effort:** Medium (3-4 days)

**Current Security:**
- ✅ .env files excluded from git
- ✅ SSL certificate validation (with `-k` option for dev)
- ✅ Clear error messages for auth failures

**Needed Enhancements:**

1. **Credential Encryption**
   ```bash
   # Encrypt .env file
   ./encrypt-credentials.sh production.env
   # Creates production.env.enc
   
   # Scripts auto-decrypt when needed
   # Uses GPG or openssl
   ```

2. **Credential Expiry Warnings**
   ```bash
   # Add to .env files:
   CREDENTIAL_EXPIRES=2026-12-31
   
   # Scripts check and warn:
   if [[ $(date +%s) -gt $(date -d "$CREDENTIAL_EXPIRES" +%s) ]]; then
       print_warning "Credentials expired on $CREDENTIAL_EXPIRES"
   fi
   ```

3. **Audit Logging**
   ```bash
   # Log sensitive operations
   audit_log() {
       local operation="$1"
       local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
       echo "[$timestamp] $USER: $operation" >> ~/.hzn-utils/audit.log
   }
   ```

4. **Secrets Management Integration**
   - Support for HashiCorp Vault
   - AWS Secrets Manager
   - Azure Key Vault

---

### LOW PRIORITY

#### Item #6: Logging Capability
**Status:** 🔴 Not Started
**Priority:** LOW
**Effort:** Small (1-2 days)

**Implementation:**
```bash
# Add to lib/common.sh
LOG_FILE="${LOG_FILE:-}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Only log if level is enabled
    case "$LOG_LEVEL" in
        DEBUG) ;;
        INFO) [[ "$level" == "DEBUG" ]] && return ;;
        WARN) [[ "$level" =~ ^(DEBUG|INFO)$ ]] && return ;;
        ERROR) [[ "$level" != "ERROR" ]] && return ;;
    esac
    
    [ -n "$LOG_FILE" ] && echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}
```

**Usage:**
```bash
export LOG_FILE=~/.hzn-utils/operations.log
export LOG_LEVEL=DEBUG
./list-a-orgs.sh
```

---

#### Item #7: Performance Optimization
**Status:** 🔴 Not Started
**Priority:** LOW
**Effort:** Medium (2-3 days)

**Optimization Opportunities:**

1. **Batch API Calls**
   ```bash
   # Instead of:
   for org in "${orgs[@]}"; do
       curl "${BASE_URL}/orgs/${org}"
   done
   
   # Use batch request (if API supports):
   curl "${BASE_URL}/orgs?ids=$(IFS=,; echo "${orgs[*]}")"
   ```

2. **Parallel Processing**
   ```bash
   # Use GNU parallel for independent operations
   parallel -j 4 curl "${BASE_URL}/orgs/{}" ::: "${orgs[@]}"
   ```

3. **Response Caching**
   ```bash
   # Cache API responses for short duration
   CACHE_DIR=~/.hzn-utils/cache
   CACHE_TTL=300  # 5 minutes
   ```

4. **Reduce jq Calls**
   - Parse JSON once, extract multiple fields
   - Use jq's multi-value output

---

#### Item #8: Documentation Improvements
**Status:** 🟡 Partially Complete
**Priority:** LOW
**Effort:** Small (1-2 days)

**Completed:**
- ✅ Comprehensive README.md
- ✅ Detailed AGENTS.md
- ✅ TESTING.md for test documentation
- ✅ ROADMAP.md for project planning

**Needed:**
- [ ] CONTRIBUTING.md with development guidelines
- [ ] examples/ directory with sample use cases
- [ ] Architecture diagram showing script relationships
- [ ] API endpoint reference
- [ ] Troubleshooting guide expansion
- [ ] Video tutorials or animated GIFs

---

#### Item #10: CI/CD Enhancements
**Status:** 🟡 Partially Implemented
**Priority:** LOW
**Effort:** Small (1-2 days)

**Current CI/CD:**
- ✅ GitHub Actions workflow for tests
- ✅ Shellcheck static analysis
- ✅ Unit and integration tests

**Enhancements Needed:**
- [ ] Code coverage reporting
- [ ] Performance benchmarking
- [ ] Security scanning (e.g., Snyk, Trivy)
- [ ] Automated release creation
- [ ] Changelog generation
- [ ] Docker image builds for testing

---

#### Item #11: Additional Scripts
**Status:** 🔴 Not Started
**Priority:** LOW
**Effort:** Large (varies by script)

**Suggested New Scripts:**

1. **Creation Scripts**
   - `create-org.sh` - Create new organizations
   - `create-user.sh` - Create new users
   - `create-service.sh` - Register new services
   - `create-pattern.sh` - Create deployment patterns

2. **Deletion Scripts**
   - `delete-org.sh` - Remove organizations
   - `delete-user.sh` - Remove users
   - `delete-node.sh` - Unregister nodes
   - `delete-service.sh` - Remove services

3. **Management Scripts**
   - `update-user.sh` - Modify user properties
   - `update-org.sh` - Modify organization settings
   - `backup-config.sh` - Backup configurations
   - `restore-config.sh` - Restore configurations
   - `migrate-org.sh` - Migrate between instances

4. **Monitoring Scripts**
   - `monitor-nodes.sh` - Real-time node status
   - `health-check.sh` - System health verification
   - `audit-report.sh` - Generate audit reports

---

#### Item #12: Code Quality Tools
**Status:** 🟡 Partially Implemented
**Priority:** LOW
**Effort:** Small (1 day)

**Current Tools:**
- ✅ Shellcheck for static analysis
- ✅ bats-core for testing

**Additional Tools:**

1. **Pre-commit Hooks**
   ```bash
   # .git/hooks/pre-commit
   #!/bin/bash
   set -e
   
   echo "Running shellcheck..."
   shellcheck *.sh lib/*.sh
   
   echo "Running tests..."
   ./run-tests.sh --unit
   
   echo "Checking for .env files..."
   if git diff --cached --name-only | grep -q '\.env$'; then
       echo "ERROR: Attempting to commit .env file!"
       exit 1
   fi
   ```

2. **Code Formatting**
   - Use `shfmt` for consistent formatting
   - Add `.editorconfig` for editor consistency

3. **Complexity Analysis**
   - Use `shellharden` for hardening suggestions
   - Measure cyclomatic complexity

4. **Documentation Linting**
   - Use `markdownlint` for markdown files
   - Validate links with `markdown-link-check`

---

## Git Workflow Pattern

When performing new work in this repository:

1. **Check for open issues first** - Ask the user if unsure whether to use an existing issue
2. **If no open issue exists:**
   - Open a new issue describing the work
   - Label it `bug` or `enhancement` depending on the type of work
   - Create the label if it doesn't exist in the repository
3. **Create a branch** with the pattern `issue-#` (e.g., `issue-3`)
4. **Before committing changes:**
   - **Always update `README.md` and `AGENTS.md`** to document any new scripts or features
   - Run tests: `./run-tests.sh`
   - Run shellcheck: `shellcheck *.sh`
5. **When committing changes:**
   - Use the `-s` sign-off flag
   - Prefix the commit title with `Issue #: ` (e.g., `Issue #3: Fix false failure report`)
6. **When opening the PR:**
   - Use the same `Issue #: ` prefix in the PR title
   - Link to the issue in the PR description
   - Ensure CI/CD tests pass

---

## Project Structure

```
hzn-utils/
├── lib/
│   └── common.sh              # Shared library (needs expansion - Item #1)
├── tests/                     # Test suite (bats-core)
│   ├── unit/                  # Unit tests
│   ├── integration/           # Integration tests
│   ├── fixtures/              # Test data
│   └── test_helper.bash       # Test utilities
├── .github/
│   └── workflows/
│       └── test.yml           # CI/CD pipeline
├── *.sh                       # Utility scripts
├── *.env                      # Credential files (not in git)
├── README.md                  # User documentation
├── AGENTS.md                  # Technical documentation
├── ROADMAP.md                 # Project roadmap
└── TESTING.md                 # Testing documentation
```

---

## Key Design Principles

1. **Three operation modes:**
   - Default: Interactive exploration with prompts
   - Verbose: Exhaustive details for troubleshooting
   - Minimal: Machine-readable JSON for automation

2. **Minimal dependencies:**
   - Bash 3.2+ compatibility (macOS support)
   - curl (required for API scripts)
   - jq (optional but recommended for JSON parsing)
   - hzn CLI (optional, only for CLI-based scripts)

3. **Security first:**
   - Never commit `.env` files
   - Support multiple credential files
   - Clear error messages for auth failures
   - Validate SSL certificates (with option to skip for dev)

4. **Error handling:**
   - Use `set -euo pipefail` for strict error handling
   - Implement trap handlers for cleanup
   - Provide helpful error messages with troubleshooting tips
   - Exit with appropriate status codes

5. **Testing:**
   - Write unit tests for shared library functions
   - Write integration tests for complete scripts
   - Run tests before committing: `./run-tests.sh`
   - Maintain test fixtures in `tests/fixtures/`

---

## Testing Commands

```bash
# Run all tests
./run-tests.sh

# Run specific test types
./run-tests.sh --unit          # Unit tests only
./run-tests.sh --integration   # Integration tests only
./run-tests.sh --shellcheck    # Static analysis only

# Run shellcheck manually
shellcheck *.sh lib/*.sh
```

---

## Next Steps (Recommended Order)

Based on impact and dependencies:

1. **Item #1: Create shared library** (HIGH PRIORITY)
   - Reduces maintenance burden by 60-70%
   - Makes all other improvements easier to implement
   - Foundation for future enhancements

2. **Item #3: Add input validation** (MEDIUM PRIORITY)
   - Prevents errors and improves user experience
   - Can be implemented incrementally
   - Builds on shared library

3. **Item #9: Security enhancements** (MEDIUM PRIORITY)
   - Protects sensitive credentials
   - Important for production use
   - Can be implemented in phases

4. **Item #5: Configuration management** (MEDIUM PRIORITY)
   - Improves flexibility and maintainability
   - Enables feature flags and customization

5. **Remaining items** as time and resources permit

---

## Success Metrics

- **Code Duplication**: Reduce from ~70% to <20%
- **Test Coverage**: Maintain >80% coverage
- **Documentation**: Keep README.md and AGENTS.md in sync
- **Security**: Zero credential leaks, all .env files excluded
- **Usability**: All scripts support 3 operation modes
- **Compatibility**: Bash 3.2+ support maintained
- **Performance**: API calls optimized, response times <2s

---

## Resources

- [Open Horizon Documentation](https://open-horizon.github.io/)
- [Open Horizon GitHub](https://github.com/open-horizon)
- [Horizon CLI Reference](https://github.com/open-horizon/anax/blob/master/docs/cli.md)
- [Exchange API Documentation](https://github.com/open-horizon/exchange-api)
- [bats-core Documentation](https://bats-core.readthedocs.io/)
- [Shellcheck Wiki](https://www.shellcheck.net/wiki/)
