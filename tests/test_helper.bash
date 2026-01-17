#!/bin/bash

# Test helper functions for bats tests

# Get the directory of the test helper
TEST_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${TEST_HELPER_DIR}/.." && pwd)"

# Export paths for use in tests
export PROJECT_ROOT
export TEST_HELPER_DIR
export FIXTURES_DIR="${TEST_HELPER_DIR}/fixtures"

# Mock functions for testing
mock_curl() {
    local response_file="$1"
    if [ -f "$response_file" ]; then
        cat "$response_file"
        return 0
    else
        echo '{"error": "mock response not found"}'
        return 1
    fi
}

# Create a temporary directory for test artifacts
setup_test_dir() {
    export TEST_TEMP_DIR=$(mktemp -d)
    echo "$TEST_TEMP_DIR"
}

# Clean up temporary test directory
cleanup_test_dir() {
    if [ -n "${TEST_TEMP_DIR:-}" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Load a fixture file
load_fixture() {
    local fixture_name="$1"
    local fixture_path="${FIXTURES_DIR}/${fixture_name}"
    
    if [ -f "$fixture_path" ]; then
        cat "$fixture_path"
    else
        echo "Fixture not found: $fixture_name" >&2
        return 1
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    
    if [[ "$haystack" =~ $needle ]]; then
        return 0
    else
        echo "Expected to find '$needle' in '$haystack'" >&2
        return 1
    fi
}

# Assert that a string does not contain a substring
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    
    if [[ ! "$haystack" =~ $needle ]]; then
        return 0
    else
        echo "Did not expect to find '$needle' in '$haystack'" >&2
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    
    if [ -f "$file" ]; then
        return 0
    else
        echo "Expected file to exist: $file" >&2
        return 1
    fi
}

# Assert that a file does not exist
assert_file_not_exists() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    else
        echo "Expected file to not exist: $file" >&2
        return 1
    fi
}

# Assert that two strings are equal
assert_equal() {
    local expected="$1"
    local actual="$2"
    
    if [ "$expected" = "$actual" ]; then
        return 0
    else
        echo "Expected: '$expected'" >&2
        echo "Actual:   '$actual'" >&2
        return 1
    fi
}

# Assert that a command succeeds
assert_success() {
    if [ "$status" -eq 0 ]; then
        return 0
    else
        echo "Expected command to succeed, but it failed with status $status" >&2
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    if [ "$status" -ne 0 ]; then
        return 0
    else
        echo "Expected command to fail, but it succeeded" >&2
        return 1
    fi
}

# Skip test if a command is not available
skip_if_missing() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        skip "$cmd is not installed"
    fi
}

# Skip test if not running in CI
skip_if_not_ci() {
    if [ -z "${CI:-}" ]; then
        skip "Test only runs in CI environment"
    fi
}

# Create a mock API response file
create_mock_response() {
    local name="$1"
    local content="$2"
    local response_file="${TEST_TEMP_DIR}/${name}.json"
    
    echo "$content" > "$response_file"
    echo "$response_file"
}

# Set up mock environment variables
setup_mock_env() {
    export HZN_EXCHANGE_URL="https://mock.example.com/v1/"
    export HZN_ORG_ID="mockorg"
    export HZN_EXCHANGE_USER_AUTH="mockuser:mockpass"
}

# Clean up mock environment variables
cleanup_mock_env() {
    unset HZN_EXCHANGE_URL
    unset HZN_ORG_ID
    unset HZN_EXCHANGE_USER_AUTH
}

# Print debug information
debug_output() {
    echo "=== DEBUG OUTPUT ===" >&2
    echo "Status: $status" >&2
    echo "Output:" >&2
    echo "$output" >&2
    echo "===================" >&2
}

# Made with Bob
