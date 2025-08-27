import 'dart:io';
import '../../data/models/chat_models.dart';

abstract class ChatRepository {
  Future<List<ChatRoom>> fetchChatRooms();
  Future<ChatRoom> createChatRoom(String name, List<String> participantNames);
  Stream<List<ChatRoom>> getChatRoomsStream();
  
  Future<List<ChatMessage>> fetchMessages(String chatRoomId, {int limit = 50});
  Future<SendMessageResponse> sendTextMessage(String chatRoomId, String senderId, String senderName, String content);
  Future<SendMessageResponse> sendImageMessage(String chatRoomId, String senderId, String senderName, File imageFile);
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId);
  
  Future<UploadImageResponse> uploadImage(File imageFile);
  
  Future<void> markMessagesAsRead(String chatRoomId, String userId);
  Future<void> deleteChatRoom(String chatRoomId);
  Future<void> deleteMessage(String messageId, String chatRoomId);
}