#!/usr/bin/env bats

# Unit tests for API key authentication support in lib/common.sh

load '../test_helper.bash'

setup() {
    # Source the common library
    source "${PROJECT_ROOT}/lib/common.sh"
    
    # Set up test environment
    export HZN_ORG_ID="test-org"
    export BASE_URL="https://test.example.com/v1"
    export JSON_ONLY=false
}

teardown() {
    # Clean up environment variables
    unset HZN_EXCHANGE_USER_AUTH
    unset IS_API_KEY
    unset AUTH_USER
    unset AUTH_PASS
    unset FULL_AUTH
}

# Test API key detection
@test "parse_auth detects API key format" {
    export HZN_EXCHANGE_USER_AUTH="apikey:abc123def456"
    
    parse_auth
    
    [ "$IS_API_KEY" = "true" ]
    [ "$AUTH_USER" = "apikey" ]
    [ "$AUTH_PASS" = "abc123def456" ]
    [ "$FULL_AUTH" = "test-org/apikey:abc123def456" ]
}

# Test regular username:password format
@test "parse_auth handles username:password format" {
    export HZN_EXCHANGE_USER_AUTH="testuser:testpass"
    
    parse_auth
    
    [ "$IS_API_KEY" = "false" ]
    [ "$AUTH_USER" = "testuser" ]
    [ "$AUTH_PASS" = "testpass" ]
    [ "$FULL_AUTH" = "test-org/testuser:testpass" ]
}

# Test org/username:password format
@test "parse_auth handles org/username:password format" {
    export HZN_EXCHANGE_USER_AUTH="myorg/testuser:testpass"
    
    parse_auth
    
    [ "$IS_API_KEY" = "false" ]
    [ "$AUTH_USER" = "testuser" ]
    [ "$AUTH_PASS" = "testpass" ]
    [ "$FULL_AUTH" = "myorg/testuser:testpass" ]
}

# Test API key with special characters
@test "parse_auth handles API key with special characters" {
    export HZN_EXCHANGE_USER_AUTH="apikey:f47ac10b-58cc-4372-a567-0e02b2c3d479"
    
    parse_auth
    
    [ "$IS_API_KEY" = "true" ]
    [ "$AUTH_USER" = "apikey" ]
    [ "$AUTH_PASS" = "f47ac10b-58cc-4372-a567-0e02b2c3d479" ]
}

# Test that IS_API_KEY is exported
@test "parse_auth exports IS_API_KEY variable" {
    export HZN_EXCHANGE_USER_AUTH="apikey:test123"
    
    parse_auth
    
    # Check if variable is exported (available in subshell)
    bash -c '[ "$IS_API_KEY" = "true" ]'
}

# Test resolve_apikey_username function exists
@test "resolve_apikey_username function is defined" {
    run type resolve_apikey_username
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "resolve_apikey_username is a function" ]]
}

# Test resolve_apikey_username returns early for non-API key auth
@test "resolve_apikey_username skips resolution for regular auth" {
    export HZN_EXCHANGE_USER_AUTH="testuser:testpass"
    export IS_API_KEY=false
    
    run resolve_apikey_username
    
    [ "$status" -eq 0 ]
}

# Test that parse_auth initializes IS_API_KEY to false
@test "parse_auth initializes IS_API_KEY to false for regular auth" {
    export HZN_EXCHANGE_USER_AUTH="testuser:testpass"
    
    parse_auth
    
    [ "$IS_API_KEY" = "false" ]
}
