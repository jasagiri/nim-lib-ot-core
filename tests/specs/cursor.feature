Feature: Cursor Transformation
  As a developer using the OT library
  I want to transform cursor positions through operations
  So that user cursors remain in logical positions during collaborative editing

  Background:
    Given a document with the content "Hello world"
    And a cursor at position 5

  Scenario: Cursor before an insertion
    When an operation inserts " beautiful" at position 7
    And the cursor is transformed through the operation
    Then the cursor position should remain at 5

  Scenario: Cursor after an insertion
    When an operation inserts " beautiful" at position 3
    And the cursor is transformed through the operation
    Then the cursor position should be 13

  Scenario: Cursor at an insertion point (own operation)
    When an operation inserts " beautiful" at position 5
    And the cursor is transformed through the operation as own
    Then the cursor position should be 15

  Scenario: Cursor at an insertion point (other's operation)
    When an operation inserts " beautiful" at position 5
    And the cursor is transformed through the operation as other's
    Then the cursor position should be 5

  Scenario: Cursor within a deletion
    When an operation deletes 5 characters from position 3
    And the cursor is transformed through the operation
    Then the cursor position should be 3

  Scenario: Cursor after a deletion
    When an operation deletes 3 characters from position 1
    And the cursor is transformed through the operation
    Then the cursor position should be 2