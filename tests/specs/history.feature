Feature: History and Undo/Redo
  As a developer using the OT library
  I want to track operation history and perform undo/redo
  So that users can revert changes and restore previous states

  Background:
    Given a document with the content "Hello world"
    And a history manager for the document

  Scenario: Push operations to history
    When I push an operation that inserts " beautiful" at position 5
    Then the document content should be "Hello beautiful world"
    And the history should have 1 operation in the undo stack
    And the history should have 0 operations in the redo stack

  Scenario: Undo an operation
    When I push an operation that inserts " beautiful" at position 5
    And I undo the operation
    Then the document content should be "Hello world"
    And the history should have 0 operations in the undo stack
    And the history should have 1 operation in the redo stack

  Scenario: Redo an operation
    When I push an operation that inserts " beautiful" at position 5
    And I undo the operation
    And I redo the operation
    Then the document content should be "Hello beautiful world"
    And the history should have 1 operation in the undo stack
    And the history should have 0 operations in the redo stack

  Scenario: Multiple operations and undo
    When I push an operation that inserts " beautiful" at position 5
    And I push an operation that inserts " and amazing" at position 15
    And I undo the operation
    Then the document content should be "Hello beautiful world"
    And the history should have 1 operation in the undo stack
    And the history should have 1 operation in the redo stack

  Scenario: Clearing the redo stack
    When I push an operation that inserts " beautiful" at position 5
    And I push an operation that inserts " and amazing" at position 15
    And I undo the operation
    And I push a new operation that inserts " very" at position 13
    Then the document content should be "Hello beautiful very world"
    And the history should have 2 operations in the undo stack
    And the history should have 0 operations in the redo stack