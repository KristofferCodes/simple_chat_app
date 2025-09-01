import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simple_chat_app/features/chat/data/models/chat_models.dart';

void main() {
  group('ChatMessage', () {
    late DateTime testTimestamp;
    late ChatMessage testMessage;

    setUp(() {
      testTimestamp = DateTime(2024, 1, 1, 12, 0, 0);
      testMessage = ChatMessage(
        id: 'test-id',
        chatRoomId: 'room-123',
        senderId: 'user-456',
        senderName: 'John Doe',
        content: 'Hello, world!',
        type: MessageType.text,
        timestamp: testTimestamp,
        imageUrl: null,
        isRead: false,
        isOptimistic: false,
      );
    });

    test('should create a valid ChatMessage instance', () {
      expect(testMessage.id, 'test-id');
      expect(testMessage.chatRoomId, 'room-123');
      expect(testMessage.senderId, 'user-456');
      expect(testMessage.senderName, 'John Doe');
      expect(testMessage.content, 'Hello, world!');
      expect(testMessage.type, MessageType.text);
      expect(testMessage.timestamp, testTimestamp);
      expect(testMessage.imageUrl, isNull);
      expect(testMessage.isRead, false);
      expect(testMessage.isOptimistic, false);
    });

    test('should support equality comparison', () {
      final message1 = ChatMessage(
        id: 'same-id',
        chatRoomId: 'room-1',
        senderId: 'user-1',
        senderName: 'User',
        content: 'Hello',
        type: MessageType.text,
        timestamp: testTimestamp,
      );

      final message2 = ChatMessage(
        id: 'same-id',
        chatRoomId: 'room-1',
        senderId: 'user-1',
        senderName: 'User',
        content: 'Hello',
        type: MessageType.text,
        timestamp: testTimestamp,
      );

      expect(message1, equals(message2));
    });

    test('copyWith should create new instance with updated values', () {
      final updatedMessage = testMessage.copyWith(
        content: 'Updated content',
        isRead: true,
      );

      expect(updatedMessage.id, testMessage.id);
      expect(updatedMessage.content, 'Updated content');
      expect(updatedMessage.isRead, true);
      expect(updatedMessage.senderId, testMessage.senderId);
    });

    test('should convert to Firestore format correctly', () {
      final firestoreData = testMessage.toFirestore();

      expect(firestoreData['id'], 'test-id');
      expect(firestoreData['chatRoomId'], 'room-123');
      expect(firestoreData['senderId'], 'user-456');
      expect(firestoreData['senderName'], 'John Doe');
      expect(firestoreData['content'], 'Hello, world!');
      expect(firestoreData['type'], 'text');
      expect(firestoreData['timestamp'], isA<Timestamp>());
      expect(firestoreData['imageUrl'], isNull);
      expect(firestoreData['isRead'], false);
    });

    test('should create from Firestore data correctly', () {
      final firestoreData = {
        'id': 'firestore-id',
        'chatRoomId': 'room-789',
        'senderId': 'user-999',
        'senderName': 'Jane Doe',
        'content': 'Firestore message',
        'type': 'text',
        'timestamp': Timestamp.fromDate(testTimestamp),
        'imageUrl': null,
        'isRead': true,
      };

      final message = ChatMessage.fromFirestore(firestoreData);

      expect(message.id, 'firestore-id');
      expect(message.chatRoomId, 'room-789');
      expect(message.senderId, 'user-999');
      expect(message.senderName, 'Jane Doe');
      expect(message.content, 'Firestore message');
      expect(message.type, MessageType.text);
      expect(message.timestamp, testTimestamp);
      expect(message.imageUrl, isNull);
      expect(message.isRead, true);
      expect(message.isOptimistic, false); // Should default to false
    });

    test('should handle image messages correctly', () {
      final imageMessage = ChatMessage(
        id: 'img-123',
        chatRoomId: 'room-456',
        senderId: 'user-789',
        senderName: 'Photo User',
        content: 'Image',
        type: MessageType.image,
        timestamp: testTimestamp,
        imageUrl: 'https://example.com/image.jpg',
      );

      final firestoreData = imageMessage.toFirestore();
      expect(firestoreData['type'], 'image');
      expect(firestoreData['imageUrl'], 'https://example.com/image.jpg');

      final recreatedMessage = ChatMessage.fromFirestore(firestoreData);
      expect(recreatedMessage.type, MessageType.image);
      expect(recreatedMessage.imageUrl, 'https://example.com/image.jpg');
    });

    test('should handle missing fields gracefully when creating from Firestore', () {
      final incompleteData = <String, dynamic>{
        'id': 'incomplete-id',
        // Missing other required fields
      };

      final message = ChatMessage.fromFirestore(incompleteData);

      expect(message.id, 'incomplete-id');
      expect(message.chatRoomId, ''); // Should default to empty string
      expect(message.senderId, '');
      expect(message.senderName, '');
      expect(message.content, '');
      expect(message.type, MessageType.text); // Should default to text
      expect(message.timestamp, isA<DateTime>());
      expect(message.isRead, false);
      expect(message.isOptimistic, false);
    });
  });

  group('ChatRoom', () {
    late DateTime testTimestamp;
    late ChatRoom testChatRoom;

    setUp(() {
      testTimestamp = DateTime(2024, 1, 1, 12, 0, 0);
      testChatRoom = ChatRoom(
        id: 'room-123',
        name: 'Test Room',
        participantIds: ['user-1', 'user-2'],
        participantNames: ['Alice', 'Bob'],
        createdAt: testTimestamp,
        updatedAt: testTimestamp,
        unreadCount: 5,
      );
    });

    test('should create a valid ChatRoom instance', () {
      expect(testChatRoom.id, 'room-123');
      expect(testChatRoom.name, 'Test Room');
      expect(testChatRoom.participantIds, ['user-1', 'user-2']);
      expect(testChatRoom.participantNames, ['Alice', 'Bob']);
      expect(testChatRoom.lastMessage, isNull);
      expect(testChatRoom.createdAt, testTimestamp);
      expect(testChatRoom.updatedAt, testTimestamp);
      expect(testChatRoom.unreadCount, 5);
    });

    test('should support equality comparison', () {
      final room1 = ChatRoom(
        id: 'same-id',
        name: 'Same Room',
        participantIds: ['user-1'],
        participantNames: ['Alice'],
        createdAt: testTimestamp,
        updatedAt: testTimestamp,
      );

      final room2 = ChatRoom(
        id: 'same-id',
        name: 'Same Room',
        participantIds: ['user-1'],
        participantNames: ['Alice'],
        createdAt: testTimestamp,
        updatedAt: testTimestamp,
      );

      expect(room1, equals(room2));
    });

    test('copyWith should work correctly', () {
      final updatedRoom = testChatRoom.copyWith(
        name: 'Updated Room Name',
        unreadCount: 10,
      );

      expect(updatedRoom.id, testChatRoom.id);
      expect(updatedRoom.name, 'Updated Room Name');
      expect(updatedRoom.unreadCount, 10);
      expect(updatedRoom.participantIds, testChatRoom.participantIds);
    });

    test('should convert to and from Firestore correctly', () {
      final firestoreData = testChatRoom.toFirestore();
      final recreatedRoom = ChatRoom.fromFirestore(firestoreData);

      expect(recreatedRoom.id, testChatRoom.id);
      expect(recreatedRoom.name, testChatRoom.name);
      expect(recreatedRoom.participantIds, testChatRoom.participantIds);
      expect(recreatedRoom.participantNames, testChatRoom.participantNames);
      expect(recreatedRoom.createdAt, testChatRoom.createdAt);
      expect(recreatedRoom.updatedAt, testChatRoom.updatedAt);
      expect(recreatedRoom.unreadCount, testChatRoom.unreadCount);
    });
  });

  group('SendMessageResponse', () {
    test('should create successful response', () {
      final message = ChatMessage(
        id: 'msg-123',
        chatRoomId: 'room-456',
        senderId: 'user-789',
        senderName: 'Test User',
        content: 'Test message',
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      final response = SendMessageResponse(
        message: message,
        success: true,
      );

      expect(response.success, true);
      expect(response.message, message);
      expect(response.error, isNull);
    });

    test('should create failure response', () {
      final message = ChatMessage(
        id: '',
        chatRoomId: 'room-456',
        senderId: 'user-789',
        senderName: 'Test User',
        content: 'Failed message',
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      final response = SendMessageResponse(
        message: message,
        success: false,
        error: 'Network error',
      );

      expect(response.success, false);
      expect(response.message, message);
      expect(response.error, 'Network error');
    });
  });
}