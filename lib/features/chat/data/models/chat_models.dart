import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }


class ChatMessage extends Equatable {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isRead;
  final bool isOptimistic; 

  const ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.imageUrl,
    this.isRead = false,
    this.isOptimistic = false, 
  });

  @override
  List<Object?> get props => [
        id,
        chatRoomId,
        senderId,
        senderName,
        content,
        type,
        timestamp,
        imageUrl,
        isRead,
        isOptimistic,
      ];

  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    String? imageUrl,
    bool? isRead,
    bool? isOptimistic,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'isRead': isRead,
    };
  }

  static ChatMessage fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      isRead: data['isRead'] ?? false,
      isOptimistic: false, 
    );
  }
}

class ChatRoom extends Equatable {
  final String id;
  final String name;
  final List<String> participantIds;
  final List<String> participantNames;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        participantIds,
        participantNames,
        lastMessage,
        createdAt,
        updatedAt,
        unreadCount,
      ];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage?.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
    };
  }

  factory ChatRoom.fromFirestore(Map<String, dynamic> data) {
    return ChatRoom(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames: List<String>.from(data['participantNames'] ?? []),
      lastMessage: data['lastMessage'] != null
          ? ChatMessage.fromFirestore(data['lastMessage'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    List<String>? participantIds,
    List<String>? participantNames,
    ChatMessage? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool clearLastMessage = false,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class SendMessageResponse extends Equatable {
  final ChatMessage message;
  final bool success;
  final String? error;

  const SendMessageResponse({
    required this.message,
    required this.success,
    this.error,
  });

  @override
  List<Object?> get props => [message, success, error];
}

class UploadImageResponse extends Equatable {
  final String imageUrl;
  final bool success;
  final String? error;

  const UploadImageResponse({
    required this.imageUrl,
    required this.success,
    this.error,
  });

  @override
  List<Object?> get props => [imageUrl, success, error];
}