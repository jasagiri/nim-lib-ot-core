Feature: Basic Text Operations
  As a developer using the OT library
  I want to perform basic text operations
  So that I can modify text documents collaboratively

  Background:
    Given a document with the content "Hello world"

  Scenario: Insert text into a document
    When I create an operation that inserts " beautiful" at position 5
    And I apply the operation to the document
    Then the document content should be "Hello beautiful world"

  Scenario: Delete text from a document
    When I create an operation that deletes 5 characters at position 6
    And I apply the operation to the document
    Then the document content should be "Hello "

  Scenario: Retain sections of text in a document
    When I create an operation that retains 6 characters, then inserts " there", then retains 5 characters
    And I apply the operation to the document
    Then the document content should be "Hello there world"

  Scenario: Compose multiple operations
    When I create an operation that inserts " beautiful" at position 5
    And I create another operation that inserts " and amazing" at position 15
    And I compose these operations
    And I apply the composed operation to the document
    Then the document content should be "Hello beautiful and amazing world"