Feature: Protocol and Serialization
  As a developer using the OT library
  I want to serialize and deserialize operations and messages
  So that they can be transmitted over the network

  Scenario: Serialize and deserialize a text operation
    Given a text operation that:
      | retains | 5 | characters |
      | inserts | " beautiful" |
      | retains | 6 | characters |
    When the operation is serialized to JSON
    And the JSON is deserialized back into an operation
    Then the deserialized operation should be identical to the original

  Scenario: Serialize and deserialize a client operation message
    Given a client with id "client1" and revision 5
    And a text operation that inserts " collaborative" at position 10
    When a client operation message is created
    And the message is serialized to JSON
    And the JSON is deserialized back into a message
    Then the deserialized message should have the same client id, revision, and operation

  Scenario: Serialize and deserialize a server operation message
    Given a server with revision 10
    And a text operation that inserts " realtime" at position 7
    When a server operation message is created for client "client2"
    And the message is serialized to JSON
    And the JSON is deserialized back into a message
    Then the deserialized message should have the same client id, revision, and operation

  Scenario: Serialize and deserialize an acknowledgment message
    Given a client with id "client1" and revision 6
    When an acknowledgment message is created
    And the message is serialized to JSON
    And the JSON is deserialized back into a message
    Then the deserialized message should have the same client id and revision