# Run all tests from each module

{.push warning[UnusedImport]: off.}
# Import standard unittest - needed for test registration
import unittest

# These imports register the tests with the unittest framework
import ./test_types
import ./test_operations
import ./test_transform
import ./test_cursor
import ./test_client
import ./test_server
import ./test_protocol
import ./test_history
{.pop.}

when isMainModule:
  echo "Running all tests..."