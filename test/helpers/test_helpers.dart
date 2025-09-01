import 'dart:io';

import 'package:simple_chat_app/features/chat/data/models/chat_models.dart';

class TestHelpers {
  static DateTime get testDateTime => DateTime(2024, 1, 1, 12, 0, 0);

  static ChatMessage createTestMessage({
    String id = 'test-msg-1',
    String chatRoomId = 'test-room-1',
    String senderId = 'test-user-1',
    String senderName = 'Test User',
    String content = 'Test message',
    MessageType type = MessageType.text,
    DateTime? timestamp,
    String? imageUrl,
    bool isRead = false,
    bool isOptimistic = false,
  }) {
    return ChatMessage(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      timestamp: timestamp ?? testDateTime,
      imageUrl: imageUrl,
      isRead: isRead,
      isOptimistic: isOptimistic,
    );
  }

  static ChatRoom createTestChatRoom({
    String id = 'test-room-1',
    String name = 'Test Room',
    List<String> participantIds = const ['user-1', 'user-2'],
    List<String> participantNames = const ['Alice', 'Bob'],
    ChatMessage? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int unreadCount = 0,
  }) {
    return ChatRoom(
      id: id,
      name: name,
      participantIds: participantIds,
      participantNames: participantNames,
      lastMessage: lastMessage,
      createdAt: createdAt ?? testDateTime,
      updatedAt: updatedAt ?? testDateTime,
      unreadCount: unreadCount,
    );
  }

  static SendMessageResponse createSuccessResponse({
    ChatMessage? message,
  }) {
    return SendMessageResponse(
      message: message ?? createTestMessage(),
      success: true,
    );
  }

  static SendMessageResponse createFailureResponse({
    ChatMessage? message,
    String error = 'Test error',
  }) {
    return SendMessageResponse(
      message: message ?? createTestMessage(),
      success: false,
      error: error,
    );
  }

  static UploadImageResponse createImageUploadSuccess({
    String imageUrl = 'cache:test-image-id',
  }) {
    return UploadImageResponse(
      imageUrl: imageUrl,
      success: true,
    );
  }

  static UploadImageResponse createImageUploadFailure({
    String error = 'Upload failed',
  }) {
    return UploadImageResponse(
      imageUrl: '',
      success: false,
      error: error,
    );
  }

  static File createMockImageFile() {
    // This creates a mock file for testing
    // In real tests, you might want to create an actual temporary file
    return File('test_assets/test_image.jpg');
  }
}