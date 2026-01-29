#!/bin/bash
# shellcheck disable=SC1091  # Ignore sourcing lib/common.sh (not specified as input)

# Script to check if the authenticated user can list services at different access levels
# Performs three-level verification (general to specific):
#   Level 1: List IBM public services - Any authenticated user
#   Level 2: List org public services - Any authenticated user
#   Level 3: List own services (public + private) - Any authenticated user
# Usage: ./can-i-list-services.sh [OPTIONS] [ENV_FILE]

# Strict error handling
set -euo pipefail

# Default output mode
VERBOSE=false
JSON_ONLY=false
ENV_FILE=""
TARGET_ORG=""
IBM_ORG="IBM"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -j|--json)
            JSON_ONLY=true
            shift
            ;;
        -o|--org)
            if [[ -n "${2:-}" ]]; then
                TARGET_ORG="$2"
                shift 2
            else
                echo "Error: --org requires an organization ID argument"
                exit 2
            fi
            ;;
        -i|--ibm-org)
            if [[ -n "${2:-}" ]]; then
                IBM_ORG="$2"
                shift 2
            else
                echo "Error: --ibm-org requires an organization ID argument"
                exit 2
            fi
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [ENV_FILE]"
            echo ""
            echo "Check if the authenticated user can list services at different access levels"
            echo ""
            echo "This script performs three-level verification (general to specific):"
            echo "  Level 1: List IBM public services - Any authenticated user"
            echo "  Level 2: List org public services - Any authenticated user"
            echo "  Level 3: List own services (public + private) - Any authenticated user"
            echo ""
            echo "Service Visibility Rules:"
            echo "  - Users can list their own public and private services"
            echo "  - Users can list all public services in their organization"
            echo "  - Users can list all public services in the IBM organization"
            echo ""
            echo "Options:"
            echo "  -o, --org ORG        Target organization to check (default: auth org)"
            echo "  -i, --ibm-org ORG    IBM organization name (default: IBM)"
            echo "  -v, --verbose        Show detailed output with API responses"
            echo "  -j, --json           Output JSON only (for scripting/automation)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Arguments:"
            echo "  ENV_FILE             Optional: Path to .env file (e.g., mycreds.env)"
            echo "                       If not provided, will prompt for selection"
            echo ""
            echo "Exit Codes:"
            echo "  0  User CAN list services at all tested levels"
            echo "  1  User CANNOT list services at one or more levels"
            echo "  2  Error (invalid arguments, API error, etc.)"
            echo ""
            echo "Examples:"
            echo "  $0                          # Check in auth org"
            echo "  $0 -o other-org             # Check in different org"
            echo "  $0 --ibm-org myibm          # Use custom IBM org name"
            echo "  $0 --json mycreds.env       # JSON output with specific .env file"
            echo "  $0 --verbose                # Detailed output for debugging"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 2
            ;;
        *)
            # Non-option argument, treat as env file
            ENV_FILE="$1"
            shift
            ;;
    esac
done

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Setup cleanup trap
# shellcheck disable=SC2119  # Function doesn't use positional parameters
setup_cleanup_trap

# Handle .env file selection and load credentials
selected_file=""  # Will be set by select_env_file
select_env_file "$ENV_FILE" || exit 2
load_credentials "$selected_file" || exit 2

# Set target org to auth org if not specified
if [ -z "$TARGET_ORG" ]; then
    TARGET_ORG="$HZN_ORG_ID"
fi

# Display configuration (unless JSON mode)
if [ "$JSON_ONLY" = false ]; then
    print_header "Permission Check: Can I List Services?"
    echo ""
    print_info "Configuration:"
    echo "  Exchange URL:       $HZN_EXCHANGE_URL"
    echo "  Auth Organization:  $HZN_ORG_ID"
    echo "  Target Organization: $TARGET_ORG"
    echo "  IBM Organization:   $IBM_ORG"
    echo "  Auth User:          ${HZN_EXCHANGE_USER_AUTH%%:*}"
    echo ""
fi

# Check if curl is installed
check_curl || exit 2

# Check if jq is installed (optional but recommended)
check_jq

# Parse authentication credentials
parse_auth

# Use the Exchange URL as-is (it should already include the API version path)
# Remove trailing slash if present
# shellcheck disable=SC2034  # BASE_URL used by test_api_access from common.sh
BASE_URL="${HZN_EXCHANGE_URL%/}"

# Resolve actual username if using API key
if [ "$IS_API_KEY" = true ]; then
    resolve_apikey_username || exit 2
fi

# ============================================================================
# PHASE 1: Three-Level Permission Testing (General → Specific)
# ============================================================================

if [ "$JSON_ONLY" = false ]; then
    print_header "Testing Access Levels (General → Specific)"
fi

# Initialize result tracking
level1_predicted=false
level1_actual=false
level1_http_code=0
level1_reason=""
level1_total_count=0
level1_public_count=0

level2_predicted=false
level2_actual=false
level2_http_code=0
level2_reason=""
level2_total_count=0
level2_public_count=0

level3_predicted=false
level3_actual=false
level3_http_code=0
level3_reason=""
level3_total_count=0
level3_public_count=0
level3_private_count=0

# ----------------------------------------------------------------------------
# Level 1: List IBM Public Services
# ----------------------------------------------------------------------------

# Predict Level 1 - all authenticated users can access IBM public services
level1_predicted=true
level1_pred_reason="All authenticated users can access IBM public services"

# Test Level 1
test_api_access "/orgs/${IBM_ORG}/services" "List IBM public services"
# shellcheck disable=SC2154  # Variables set by test_api_access from common.sh
level1_actual="$test_can_access"
# shellcheck disable=SC2154  # test_http_code set by test_api_access
level1_http_code="$test_http_code"

if [ "$level1_actual" = "true" ]; then
    level1_reason="Successfully listed services"
    # shellcheck disable=SC2154  # test_response_body set by test_api_access
    level1_total_count=$(count_json_items "$test_response_body" "services")
    
    # Count public services only
    if [ "$JQ_AVAILABLE" = true ]; then
        level1_public_count=$(echo "$test_response_body" | jq '[.services[] | select(.public == true)] | length' 2>/dev/null || echo "0")
    else
        # Fallback parsing for public services
        level1_public_count=$(echo "$test_response_body" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len([s for s in data.get('services', {}).values() if s.get('public', False)]))" 2>/dev/null || echo "0")
    fi
elif [ "$level1_http_code" -eq 401 ]; then
    level1_reason="Unauthorized"
elif [ "$level1_http_code" -eq 403 ]; then
    level1_reason="Forbidden"
elif [ "$level1_http_code" -eq 404 ]; then
    level1_reason="IBM organization not found"
else
    level1_reason="HTTP $level1_http_code"
fi

# Display Level 1 result
format_level_result 1 "List IBM Public Services (Org: $IBM_ORG)" \
    "$level1_predicted" "$level1_pred_reason" \
    "$level1_actual" "$level1_reason" "$level1_http_code"

if [ "$JSON_ONLY" = false ] && [ "$level1_actual" = "true" ]; then
    echo "  Services found: $level1_public_count public (of $level1_total_count total)"
fi

if [ "$JSON_ONLY" = false ] && [ "$VERBOSE" = true ] && [ "$level1_actual" = "true" ]; then
    echo ""
    print_info "Level 1 API Response:"
    if [ "$JQ_AVAILABLE" = true ]; then
        echo "$test_response_body" | jq '.'
    else
        echo "$test_response_body" | python3 -m json.tool 2>/dev/null || echo "$test_response_body"
    fi
fi

# ----------------------------------------------------------------------------
# Level 2: List Organization's Public Services
# ----------------------------------------------------------------------------

# Predict Level 2 - all authenticated users can access public services
level2_predicted=true
level2_pred_reason="All authenticated users can access public services in any organization"

# Test Level 2
test_api_access "/orgs/${TARGET_ORG}/services" "List organization's public services"
level2_actual="$test_can_access"
level2_http_code="$test_http_code"

if [ "$level2_actual" = "true" ]; then
    level2_reason="Successfully listed services"
    level2_total_count=$(count_json_items "$test_response_body" "services")
    
    # Count public services only
    if [ "$JQ_AVAILABLE" = true ]; then
        level2_public_count=$(echo "$test_response_body" | jq '[.services[] | select(.public == true)] | length' 2>/dev/null || echo "0")
    else
        # Fallback parsing for public services
        level2_public_count=$(echo "$test_response_body" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len([s for s in data.get('services', {}).values() if s.get('public', False)]))" 2>/dev/null || echo "0")
    fi
elif [ "$level2_http_code" -eq 401 ]; then
    level2_reason="Unauthorized"
elif [ "$level2_http_code" -eq 403 ]; then
    level2_reason="Forbidden"
elif [ "$level2_http_code" -eq 404 ]; then
    level2_reason="Organization not found"
else
    level2_reason="HTTP $level2_http_code"
fi

# Display Level 2 result
format_level_result 2 "List Organization's Public Services (Org: $TARGET_ORG)" \
    "$level2_predicted" "$level2_pred_reason" \
    "$level2_actual" "$level2_reason" "$level2_http_code"

if [ "$JSON_ONLY" = false ] && [ "$level2_actual" = "true" ]; then
    echo "  Services found: $level2_public_count public (of $level2_total_count total)"
fi

if [ "$JSON_ONLY" = false ] && [ "$VERBOSE" = true ] && [ "$level2_actual" = "true" ]; then
    echo ""
    print_info "Level 2 API Response:"
    if [ "$JQ_AVAILABLE" = true ]; then
        echo "$test_response_body" | jq '.'
    else
        echo "$test_response_body" | python3 -m json.tool 2>/dev/null || echo "$test_response_body"
    fi
fi

# ----------------------------------------------------------------------------
# Level 3: List Own Services (Public + Private)
# ----------------------------------------------------------------------------

# Predict Level 3 - all authenticated users can list their own services
level3_predicted=true
level3_pred_reason="All authenticated users can list their own services"

# Construct owner parameter in org/user format
OWNER_ID="${HZN_ORG_ID}/${AUTH_USER}"

# Test Level 3
test_api_access "/orgs/${HZN_ORG_ID}/services?owner=${OWNER_ID}" "List own services"
level3_actual="$test_can_access"
level3_http_code="$test_http_code"

if [ "$level3_actual" = "true" ]; then
    level3_reason="Successfully listed own services"
    level3_total_count=$(count_json_items "$test_response_body" "services")
    
    # Count public and private services
    if [ "$JQ_AVAILABLE" = true ]; then
        level3_public_count=$(echo "$test_response_body" | jq '[.services[] | select(.public == true)] | length' 2>/dev/null || echo "0")
    else
        # Fallback parsing for public services
        level3_public_count=$(echo "$test_response_body" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len([s for s in data.get('services', {}).values() if s.get('public', False)]))" 2>/dev/null || echo "0")
    fi
    level3_private_count=$((level3_total_count - level3_public_count))
elif [ "$level3_http_code" -eq 401 ]; then
    level3_reason="Unauthorized"
elif [ "$level3_http_code" -eq 403 ]; then
    level3_reason="Forbidden"
else
    level3_reason="HTTP $level3_http_code"
fi

# Display Level 3 result
format_level_result 3 "List Own Services (Public + Private)" \
    "$level3_predicted" "$level3_pred_reason" \
    "$level3_actual" "$level3_reason" "$level3_http_code"

if [ "$JSON_ONLY" = false ] && [ "$level3_actual" = "true" ]; then
    echo "  Services found: $level3_total_count total ($level3_public_count public, $level3_private_count private)"
fi

if [ "$JSON_ONLY" = false ] && [ "$VERBOSE" = true ] && [ "$level3_actual" = "true" ]; then
    echo ""
    print_info "Level 3 API Response:"
    if [ "$JQ_AVAILABLE" = true ]; then
        echo "$test_response_body" | jq '.'
    else
        echo "$test_response_body" | python3 -m json.tool 2>/dev/null || echo "$test_response_body"
    fi
fi

# ============================================================================
# PHASE 2: Summary and Results
# ============================================================================

if [ "$JSON_ONLY" = false ]; then
    echo ""
    print_header "Result"
    echo ""
fi

# Determine overall result and exit code
exit_code=0
result_message=""

# Check if all levels passed
if [ "$level1_actual" = "true" ] && [ "$level2_actual" = "true" ] && [ "$level3_actual" = "true" ]; then
    exit_code=0
    result_message="User can list services at all levels"
elif [ "$level3_actual" = "true" ]; then
    exit_code=1
    result_message="User can list own services but not all public services"
else
    exit_code=1
    result_message="User cannot list services at one or more levels"
fi

# Output results
if [ "$JSON_ONLY" = true ]; then
    # JSON output mode
    cat << EOF
{
  "target_org": "$TARGET_ORG",
  "auth_org": "$HZN_ORG_ID",
  "ibm_org": "$IBM_ORG",
  "auth_user": "$AUTH_USER",
  "levels": {
    "level1": {
      "description": "List IBM public services",
      "predicted": $level1_predicted,
      "predicted_reason": "$level1_pred_reason",
      "actual": $level1_actual,
      "actual_reason": "$level1_reason",
      "http_code": $level1_http_code,
      "services_found": $level1_total_count,
      "public_services": $level1_public_count,
      "public_only": true
    },
    "level2": {
      "description": "List organization's public services",
      "predicted": $level2_predicted,
      "predicted_reason": "$level2_pred_reason",
      "actual": $level2_actual,
      "actual_reason": "$level2_reason",
      "http_code": $level2_http_code,
      "services_found": $level2_total_count,
      "public_services": $level2_public_count,
      "public_only": true
    },
    "level3": {
      "description": "List own services (public + private)",
      "predicted": $level3_predicted,
      "predicted_reason": "$level3_pred_reason",
      "actual": $level3_actual,
      "actual_reason": "$level3_reason",
      "http_code": $level3_http_code,
      "services_found": $level3_total_count,
      "public_services": $level3_public_count,
      "private_services": $level3_private_count
    }
  },
  "result": {
    "message": "$result_message",
    "can_list_ibm_public": $level1_actual,
    "can_list_org_public": $level2_actual,
    "can_list_own_services": $level3_actual,
    "exit_code": $exit_code
  }
}
EOF
else
    # Human-readable output
    if [ "$exit_code" -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $result_message"
    else
        echo -e "  ${YELLOW}✓${NC} $result_message"
    fi
    
    echo ""
    print_info "Summary:"
    echo "  Can list IBM public services:    $([ "$level1_actual" = "true" ] && echo "YES ($level1_public_count services)" || echo "NO")"
    echo "  Can list org public services:    $([ "$level2_actual" = "true" ] && echo "YES ($level2_public_count services)" || echo "NO")"
    echo "  Can list own services:           $([ "$level3_actual" = "true" ] && echo "YES ($level3_total_count services: $level3_public_count public, $level3_private_count private)" || echo "NO")"
    echo ""
    
    if [ "$exit_code" -ne 0 ]; then
        print_info "Troubleshooting:"
        if [ "$level1_actual" = "false" ]; then
            echo "  - IBM organization '$IBM_ORG' may not exist or be accessible"
            echo "  - Try using --ibm-org flag to specify correct IBM org name"
        fi
        if [ "$level2_actual" = "false" ]; then
            echo "  - Target organization '$TARGET_ORG' may not exist"
            echo "  - Verify organization name is correct"
        fi
        if [ "$level3_actual" = "false" ]; then
            echo "  - Authentication may have failed"
            echo "  - Verify credentials are correct"
        fi
        echo ""
    fi
fi

exit $exit_code
