# Testing Guide for hzn-utils

This document describes the testing infrastructure and how to run tests for the hzn-utils project.

## Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Prerequisites](#prerequisites)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Continuous Integration](#continuous-integration)
- [Troubleshooting](#troubleshooting)

## Overview

The hzn-utils project uses [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for testing bash scripts. The test suite includes:

- **Unit tests**: Test individual functions in `lib/common.sh`
- **Integration tests**: Test complete scripts end-to-end
- **ShellCheck**: Static analysis for shell scripts
- **Security checks**: Scan for hardcoded credentials and security issues

## Test Structure

```
hzn-utils/
├── tests/
│   ├── fixtures/              # Test data and mock files
│   │   ├── valid.env          # Valid credentials for testing
│   │   ├── invalid.env        # Invalid credentials (missing fields)
│   │   ├── partial.env        # Partial credentials
│   │   └── with-org-prefix.env # Credentials with org prefix
│   ├── unit/                  # Unit tests
│   │   └── test_common.bats   # Tests for lib/common.sh
│   ├── integration/           # Integration tests
│   │   ├── test_list_orgs.bats    # Tests for list-orgs.sh
│   │   └── test_api_scripts.bats  # Tests for API scripts
│   └── test_helper.bash       # Shared test utilities
├── run-tests.sh               # Test runner script
└── .github/workflows/test.yml # CI/CD configuration
```

## Prerequisites

### Required Tools

1. **bats-core** - Bash testing framework

   **macOS (Homebrew):**
   ```bash
   brew install bats-core
   ```

   **Linux (apt):**
   ```bash
   sudo apt-get install bats
   ```

   **npm:**
   ```bash
   npm install -g bats
   ```

   **From source:**
   ```bash
   git clone https://github.com/bats-core/bats-core.git
   cd bats-core
   sudo ./install.sh /usr/local
   ```

2. **curl** - HTTP client (usually pre-installed)
   ```bash
   curl --version
   ```

### Optional Tools

These tools enhance the testing experience but are not required:

1. **shellcheck** - Shell script static analysis
   ```bash
   # macOS
   brew install shellcheck
   
   # Linux
   sudo apt-get install shellcheck
   ```

2. **jq** - JSON processor for better test output
   ```bash
   # macOS
   brew install jq
   
   # Linux
   sudo apt-get install jq
   ```

## Running Tests

### Quick Start

Run all tests:
```bash
./run-tests.sh
```

### Test Options

The `run-tests.sh` script supports several options:

```bash
# Run only unit tests
./run-tests.sh --unit

# Run only integration tests
./run-tests.sh --integration

# Run only shellcheck
./run-tests.sh --shellcheck

# Verbose output
./run-tests.sh --verbose

# Show help
./run-tests.sh --help
```

### Running Tests Directly with bats

You can also run bats directly:

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/unit/test_common.bats

# Run with verbose output
bats -t tests/unit/test_common.bats

# Run with timing information
bats --timing tests/
```

### Running Individual Test Cases

To run a specific test case:

```bash
# Run a single test by line number
bats tests/unit/test_common.bats:25

# Run tests matching a pattern
bats -f "print_info" tests/unit/test_common.bats
```

## Writing Tests

### Test File Structure

All test files should follow this structure:

```bash
#!/usr/bin/env bats

# Load test helper
load '../test_helper'

setup() {
    # Run before each test
    setup_test_dir
    setup_mock_env
}

teardown() {
    # Run after each test
    cleanup_test_dir
    cleanup_mock_env
}

@test "descriptive test name" {
    # Test code here
    run command_to_test
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected output" ]]
}
```

### Test Assertions

Common bats assertions:

```bash
# Exit status
[ "$status" -eq 0 ]      # Command succeeded
[ "$status" -ne 0 ]      # Command failed
[ "$status" -eq 1 ]      # Specific exit code

# Output matching
[[ "$output" =~ "pattern" ]]     # Output contains pattern
[ "$output" = "exact match" ]    # Exact output match
[ -z "$output" ]                 # Output is empty
[ -n "$output" ]                 # Output is not empty

# File checks
[ -f "file.txt" ]        # File exists
[ -d "directory" ]       # Directory exists
[ -x "script.sh" ]       # File is executable
```

### Using Test Helpers

The `test_helper.bash` provides useful functions:

```bash
# Setup and cleanup
setup_test_dir          # Create temporary test directory
cleanup_test_dir        # Remove temporary test directory
setup_mock_env          # Set mock environment variables
cleanup_mock_env        # Unset mock environment variables

# Assertions
assert_contains "haystack" "needle"
assert_not_contains "haystack" "needle"
assert_file_exists "path/to/file"
assert_file_not_exists "path/to/file"
assert_equal "expected" "actual"
assert_success          # Check $status is 0
assert_failure          # Check $status is not 0

# Utilities
load_fixture "filename"              # Load test fixture
create_mock_response "name" "json"   # Create mock API response
skip_if_missing "command"            # Skip test if command not available
skip_if_not_ci                       # Skip test if not in CI
```

### Example Unit Test

```bash
@test "load_credentials succeeds with valid env file" {
    run load_credentials "${FIXTURES_DIR}/valid.env"
    
    assert_success
    [ "$HZN_EXCHANGE_URL" = "https://test.example.com/v1/" ]
    [ "$HZN_ORG_ID" = "testorg" ]
    [ "$HZN_EXCHANGE_USER_AUTH" = "testuser:testpass123" ]
}
```

### Example Integration Test

```bash
@test "list-a-orgs.sh accepts --json flag" {
    skip_if_missing "curl"
    
    run "${PROJECT_ROOT}/list-a-orgs.sh" --json "${FIXTURES_DIR}/valid.env"
    
    # May fail if Exchange not reachable, but should accept the flag
    [ "$status" -ge 0 ]
}
```

### Testing Best Practices

1. **Use descriptive test names**: Test names should clearly describe what is being tested
2. **One assertion per test**: Keep tests focused on a single behavior
3. **Use fixtures**: Store test data in `tests/fixtures/` directory
4. **Clean up after tests**: Use `teardown()` to remove temporary files
5. **Skip unavailable tests**: Use `skip_if_missing` for optional dependencies
6. **Test error cases**: Don't just test the happy path
7. **Mock external dependencies**: Don't rely on external services in tests

## Continuous Integration

### GitHub Actions

Tests run automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Manual workflow dispatch

The CI pipeline includes:

1. **ShellCheck**: Static analysis of all shell scripts
2. **Unit Tests**: Run on Ubuntu and macOS
3. **Integration Tests**: Run on Ubuntu and macOS
4. **Security Scan**: Check for hardcoded credentials
5. **Lint Check**: Validate script permissions and structure
6. **Documentation Check**: Ensure required docs exist

### Viewing CI Results

1. Go to the "Actions" tab in GitHub
2. Click on the workflow run
3. View logs for each job
4. Download test artifacts if available

### Local CI Simulation

Run the same checks locally:

```bash
# Run shellcheck
shellcheck *.sh lib/*.sh

# Run all tests
./run-tests.sh

# Check for credentials
grep -r "password\|secret\|token" --include="*.sh" --exclude-dir=tests .

# Validate structure
[ -d "tests/unit" ] && [ -d "tests/integration" ] && echo "Structure OK"
```

## Troubleshooting

### Common Issues

#### bats not found

**Problem**: `bats: command not found`

**Solution**: Install bats-core (see [Prerequisites](#prerequisites))

#### Tests fail with "command not found"

**Problem**: Tests fail because required tools are missing

**Solution**: 
- Check which tool is missing from the error message
- Install the tool or skip tests that require it
- Tests will automatically skip if optional tools are missing

#### Permission denied errors

**Problem**: `Permission denied` when running scripts

**Solution**:
```bash
chmod +x run-tests.sh
chmod +x *.sh
```

#### Tests pass locally but fail in CI

**Problem**: Tests work on your machine but fail in GitHub Actions

**Solution**:
- Check if you're using macOS-specific features (CI uses Ubuntu)
- Ensure all dependencies are listed in the workflow file
- Check for hardcoded paths or assumptions about the environment
- Review CI logs for specific error messages

#### Mock credentials not working

**Problem**: Tests fail because they try to connect to real Exchange

**Solution**:
- Ensure `setup_mock_env` is called in `setup()`
- Check that tests use `${FIXTURES_DIR}/valid.env`
- Verify mock environment variables are set correctly

### Debug Mode

Run tests with debug output:

```bash
# Verbose bats output
bats -t tests/unit/test_common.bats

# Show all commands
bash -x run-tests.sh --unit

# Debug specific test
bats -f "test name" tests/unit/test_common.bats
```

### Getting Help

If you encounter issues:

1. Check this documentation
2. Review test logs for error messages
3. Run tests with verbose output
4. Check the [bats-core documentation](https://bats-core.readthedocs.io/)
5. Open an issue on GitHub with:
   - Error message
   - Steps to reproduce
   - Your environment (OS, bash version, bats version)

## Contributing Tests

When contributing new features:

1. **Write tests first** (TDD approach recommended)
2. **Add unit tests** for new functions in `lib/common.sh`
3. **Add integration tests** for new scripts
4. **Update fixtures** if new test data is needed
5. **Run all tests** before submitting PR
6. **Update this documentation** if adding new test patterns

### Test Coverage Goals

- All functions in `lib/common.sh` should have unit tests
- All scripts should have integration tests
- Error cases should be tested
- Edge cases should be covered
- Aim for >80% code coverage

## Additional Resources

- [bats-core documentation](https://bats-core.readthedocs.io/)
- [ShellCheck wiki](https://github.com/koalaman/shellcheck/wiki)
- [Bash testing best practices](https://github.com/bats-core/bats-core#best-practices)
- [GitHub Actions documentation](https://docs.github.com/en/actions)

## License

This testing infrastructure is part of the hzn-utils project and follows the same license.