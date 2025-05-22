Feature: Client-Server Collaboration
  As a developer using the OT library
  I want to synchronize operations between clients through a server
  So that multiple users can collaborate on the same document

  Background:
    Given a server with an initial document "Hello world"
    And client 1 connected to the server
    And client 2 connected to the server

  Scenario: Basic client-server synchronization
    When client 1 applies a local operation that inserts " beautiful" at position 5
    And the server receives client 1's operation
    And the server broadcasts the operation to client 2
    Then client 1's document content should be "Hello beautiful world"
    And client 2's document content should be "Hello beautiful world"
    And the server's document content should be "Hello beautiful world"

  Scenario: Handling concurrent edits
    When client 1 applies a local operation that inserts " beautiful" at position 5
    And before receiving any updates, client 2 applies a local operation that inserts " amazing" at position 5
    And the server receives client 1's operation
    And the server broadcasts the operation to client 2
    And client 2 applies the remote operation
    And the server receives client 2's operation
    And the server broadcasts the operation to client 1
    And client 1 applies the remote operation
    Then client 1's document content should be "Hello beautiful amazing world"
    And client 2's document content should be "Hello beautiful amazing world"
    And the server's document content should be "Hello beautiful amazing world"

  Scenario: Client state transitions
    Given client 1 in synchronized state
    When client 1 applies a local operation
    Then client 1 should be in awaiting confirmation state
    When the server acknowledges client 1's operation
    Then client 1 should be in synchronized state
    When client 1 applies a local operation
    And before receiving confirmation, client 1 applies another local operation
    Then client 1 should be in awaiting with buffer state
    When the server acknowledges client 1's first operation
    Then client 1 should be in awaiting confirmation state