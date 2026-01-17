#!/usr/bin/env bats

# Load the common library
load '../test_helper'

setup() {
    # Source the common library
    source "${BATS_TEST_DIRNAME}/../../lib/common.sh"
    
    # Set up test environment
    export TEST_MODE=true
    export JSON_ONLY=false
}

teardown() {
    # Clean up any test artifacts
    unset TEST_MODE
    unset JSON_ONLY
    unset HZN_EXCHANGE_URL
    unset HZN_ORG_ID
    unset HZN_EXCHANGE_USER_AUTH
}

# Test print functions
@test "print_info outputs correctly" {
    run print_info "test message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test message" ]]
}

@test "print_success outputs correctly" {
    run print_success "success message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "success message" ]]
}

@test "print_error outputs to stderr" {
    run print_error "error message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "error message" ]]
}

@test "print_warning outputs correctly" {
    run print_warning "warning message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "warning message" ]]
}

@test "print_header outputs correctly" {
    run print_header "Test Header"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Test Header" ]]
}

@test "print functions respect JSON_ONLY mode" {
    export JSON_ONLY=true
    run print_info "should not appear"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# Test credential loading
@test "load_credentials succeeds with valid env file" {
    load_credentials "${BATS_TEST_DIRNAME}/../fixtures/valid.env"
    [ "$HZN_EXCHANGE_URL" = "https://test.example.com/v1/" ]
    [ "$HZN_ORG_ID" = "testorg" ]
    [ "$HZN_EXCHANGE_USER_AUTH" = "testuser:testpass123" ]
}

@test "load_credentials fails with missing variables" {
    run load_credentials "${BATS_TEST_DIRNAME}/../fixtures/invalid.env"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing required environment variables" ]]
}

@test "load_credentials fails with partial credentials" {
    run load_credentials "${BATS_TEST_DIRNAME}/../fixtures/partial.env"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "HZN_ORG_ID" ]]
}

@test "load_credentials fails with non-existent file" {
    run load_credentials "${BATS_TEST_DIRNAME}/../fixtures/nonexistent.env"
    [ "$status" -ne 0 ]
}

# Test authentication parsing
@test "parse_auth handles simple auth format" {
    export HZN_ORG_ID="testorg"
    export HZN_EXCHANGE_USER_AUTH="testuser:testpass123"
    
    parse_auth
    [ "$AUTH_USER" = "testuser" ]
    [ "$AUTH_PASS" = "testpass123" ]
    [ "$FULL_AUTH" = "testorg/testuser:testpass123" ]
}

@test "parse_auth handles org-prefixed auth format" {
    export HZN_ORG_ID="testorg"
    export HZN_EXCHANGE_USER_AUTH="testorg/testuser:testpass123"
    
    parse_auth
    [ "$AUTH_USER" = "testuser" ]
    [ "$FULL_AUTH" = "testorg/testuser:testpass123" ]
}

# Test tool availability checks
@test "check_curl succeeds when curl is available" {
    skip_if_missing "curl"
    run check_curl
    [ "$status" -eq 0 ]
}

@test "check_jq sets JQ_AVAILABLE correctly" {
    check_jq
    # JQ_AVAILABLE should be set to true or false
    [[ "$JQ_AVAILABLE" == "true" ]] || [[ "$JQ_AVAILABLE" == "false" ]]
}

# Test URL validation
@test "validate_url accepts valid HTTP URL" {
    run validate_url "http://example.com"
    [ "$status" -eq 0 ]
}

@test "validate_url accepts valid HTTPS URL" {
    run validate_url "https://example.com/api/v1"
    [ "$status" -eq 0 ]
}

@test "validate_url rejects invalid URL" {
    run validate_url "not-a-url"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid URL" ]]
}

@test "validate_url rejects empty URL" {
    run validate_url ""
    [ "$status" -eq 1 ]
}

# Test organization ID validation
@test "validate_org_id accepts valid org ID" {
    run validate_org_id "myorg"
    [ "$status" -eq 0 ]
}

@test "validate_org_id accepts org ID with hyphens" {
    run validate_org_id "my-org-123"
    [ "$status" -eq 0 ]
}

@test "validate_org_id accepts org ID with underscores" {
    run validate_org_id "my_org_123"
    [ "$status" -eq 0 ]
}

@test "validate_org_id rejects org ID with spaces" {
    run validate_org_id "my org"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid organization ID" ]]
}

@test "validate_org_id rejects org ID with special characters" {
    run validate_org_id "my@org"
    [ "$status" -eq 1 ]
}

@test "validate_org_id rejects empty org ID" {
    run validate_org_id ""
    [ "$status" -eq 1 ]
}

# Test environment file selection
@test "find_env_files populates env_files array" {
    cd "${BATS_TEST_DIRNAME}/../fixtures"
    find_env_files
    # Should find at least the fixture env files
    [ ${#env_files[@]} -gt 0 ]
}

@test "select_env_file accepts file argument" {
    export JSON_ONLY=true
    select_env_file "${BATS_TEST_DIRNAME}/../fixtures/valid.env"
    [ "$selected_file" = "${BATS_TEST_DIRNAME}/../fixtures/valid.env" ]
}

@test "select_env_file fails with non-existent file" {
    run select_env_file "nonexistent.env"
    [ "$status" -eq 1 ]
}

# Test display_config function
@test "display_config shows configuration" {
    export HZN_EXCHANGE_URL="https://test.example.com/v1/"
    export HZN_ORG_ID="testorg"
    export HZN_EXCHANGE_USER_AUTH="testuser:testpass"
    export JSON_ONLY=false
    
    run display_config
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Configuration" ]]
    [[ "$output" =~ "testorg" ]]
}

@test "display_config respects JSON_ONLY mode" {
    export JSON_ONLY=true
    run display_config
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}