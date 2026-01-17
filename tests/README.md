# Test Suite for hzn-utils

This directory contains the test suite for the hzn-utils project.

## Directory Structure

```
tests/
├── fixtures/              # Test data and mock files
│   ├── valid.env          # Valid credentials for testing
│   ├── invalid.env        # Invalid credentials (missing fields)
│   ├── partial.env        # Partial credentials
│   └── with-org-prefix.env # Credentials with org prefix
├── unit/                  # Unit tests
│   └── test_common.bats   # Tests for lib/common.sh functions
├── integration/           # Integration tests
│   ├── test_list_orgs.bats    # Tests for list-orgs.sh
│   └── test_api_scripts.bats  # Tests for API-based scripts
├── test_helper.bash       # Shared test utilities and helpers
└── README.md             # This file
```

## Running Tests

From the project root:

```bash
# Run all tests
./run-tests.sh

# Run only unit tests
./run-tests.sh --unit

# Run only integration tests
./run-tests.sh --integration

# Run with bats directly
bats tests/
```

## Test Fixtures

The `fixtures/` directory contains sample `.env` files used for testing:

- **valid.env**: Complete, valid credentials
- **invalid.env**: Missing required fields (for error testing)
- **partial.env**: Partial credentials (for validation testing)
- **with-org-prefix.env**: Credentials with organization prefix in auth string

These fixtures are used to test credential loading, validation, and error handling.

## Writing Tests

### Unit Tests

Unit tests should test individual functions in isolation. Place them in `tests/unit/`.

Example:
```bash
@test "load_credentials succeeds with valid env file" {
    run load_credentials "${FIXTURES_DIR}/valid.env"
    [ "$status" -eq 0 ]
    [ "$HZN_EXCHANGE_URL" = "https://test.example.com/v1/" ]
}
```

### Integration Tests

Integration tests should test complete scripts end-to-end. Place them in `tests/integration/`.

Example:
```bash
@test "list-a-orgs.sh accepts --json flag" {
    skip_if_missing "curl"
    run "${PROJECT_ROOT}/list-a-orgs.sh" --json "${FIXTURES_DIR}/valid.env"
    [ "$status" -ge 0 ]
}
```

## Test Helpers

The `test_helper.bash` file provides common utilities:

- `setup_test_dir` / `cleanup_test_dir`: Manage temporary directories
- `setup_mock_env` / `cleanup_mock_env`: Set/unset mock environment variables
- `assert_*`: Various assertion helpers
- `skip_if_missing`: Skip tests if required tools are unavailable
- `load_fixture`: Load test fixture files

## Best Practices

1. **Use descriptive test names**: Clearly describe what is being tested
2. **Clean up after tests**: Use `teardown()` to remove temporary files
3. **Skip unavailable tests**: Use `skip_if_missing` for optional dependencies
4. **Test error cases**: Don't just test the happy path
5. **Use fixtures**: Store test data in the fixtures directory
6. **Keep tests independent**: Each test should be able to run in isolation

## More Information

For comprehensive testing documentation, see [TESTING.md](../TESTING.md) in the project root.