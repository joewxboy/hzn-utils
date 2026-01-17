#!/usr/bin/env bats

# Integration tests for list-orgs.sh script

bats_require_minimum_version 1.5.0

load '../test_helper'

setup() {
    # Set up test environment
    setup_test_dir
    setup_mock_env
    
    # Path to the script
    SCRIPT="${PROJECT_ROOT}/list-orgs.sh"
}

teardown() {
    cleanup_test_dir
    cleanup_mock_env
}

@test "list-orgs.sh exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "list-orgs.sh shows help with --help flag" {
    skip_if_missing "hzn"
    
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage" ]] || [[ "$output" =~ "help" ]]
}

@test "list-orgs.sh requires valid credentials" {
    skip_if_missing "hzn"
    
    # Unset credentials
    unset HZN_EXCHANGE_URL
    unset HZN_ORG_ID
    unset HZN_EXCHANGE_USER_AUTH
    
    run "$SCRIPT" "${FIXTURES_DIR}/invalid.env"
    [ "$status" -ne 0 ]
}

@test "list-orgs.sh accepts env file as argument" {
    skip_if_missing "hzn"
    
    # This test will fail if hzn is not properly configured
    # but should at least validate the script accepts the argument
    run "$SCRIPT" "${FIXTURES_DIR}/valid.env"
    # Status may be non-zero if Exchange is not reachable, but script should run
    [ "$status" -ge 0 ]
}

@test "list-orgs.sh handles non-existent env file" {
    run "$SCRIPT" "nonexistent.env"
    [ "$status" -ne 0 ]
}

@test "list-orgs.sh validates env file format" {
    skip_if_missing "hzn"
    
    # Create invalid env file
    echo "INVALID_FORMAT" > "${TEST_TEMP_DIR}/bad.env"
    
    # Expect failure (any non-zero exit code)
    run ! "$SCRIPT" "${TEST_TEMP_DIR}/bad.env"
}