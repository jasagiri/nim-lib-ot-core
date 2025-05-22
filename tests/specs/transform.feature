Feature: Operational Transformation
  As a developer using the OT library
  I want to transform concurrent operations
  So that they can be applied in any order with the same result

  Background:
    Given a document with the content "Hello world"

  Scenario: Transform insert operations at the same position
    When user 1 inserts " beautiful" at position 5
    And user 2 inserts " amazing" at position 5
    And the operations are transformed
    And user 1's operation is applied first, then user 2's transformed operation
    Then the document content should be "Hello beautiful amazing world"
    And if user 2's operation is applied first, then user 1's transformed operation
    Then the document content should be "Hello beautiful amazing world"

  Scenario: Transform insert and delete operations
    When user 1 inserts " very" at position 5
    And user 2 deletes 5 characters at position 6
    And the operations are transformed
    And user 1's operation is applied first, then user 2's transformed operation
    Then the document content should be "Hello very"
    And if user 2's operation is applied first, then user 1's transformed operation
    Then the document content should be "Hello very"

  Scenario: Transform operations affecting different parts of the document
    When user 1 inserts " very" at position 5
    And user 2 inserts " collaborative" at position 11
    And the operations are transformed
    And user 1's operation is applied first, then user 2's transformed operation
    Then the document content should be "Hello very world collaborative"
    And if user 2's operation is applied first, then user 1's transformed operation
    Then the document content should be "Hello very world collaborative"