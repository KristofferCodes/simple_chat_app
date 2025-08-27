part of 'chat_bloc.dart';

@immutable
abstract class ChatEvent extends Equatable {}

class FetchChatRoomsEvent extends ChatEvent {
  final bool isRefresh;

  FetchChatRoomsEvent({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class CreateChatRoomEvent extends ChatEvent {
  final String name;
  final List<String> participantNames;

  CreateChatRoomEvent({
    required this.name,
    required this.participantNames,
  });

  @override
  List<Object?> get props => [name, participantNames];
}

class SelectChatRoomEvent extends ChatEvent {
  final String chatRoomId;

  SelectChatRoomEvent({required this.chatRoomId});

  @override
  List<Object?> get props => [chatRoomId];
}

class StartChatRoomsStreamEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class ChatRoomsStreamUpdatedEvent extends ChatEvent {
  final List<ChatRoom> chatRooms;

  ChatRoomsStreamUpdatedEvent({required this.chatRooms});

  @override
  List<Object?> get props => [chatRooms];
}

class DeleteChatRoomEvent extends ChatEvent {
  final String chatRoomId;

  DeleteChatRoomEvent({required this.chatRoomId});

  @override
  List<Object?> get props => [chatRoomId];
}

class FetchMessagesEvent extends ChatEvent {
  final String chatRoomId;
  final bool isRefresh;

  FetchMessagesEvent({
    required this.chatRoomId,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [chatRoomId, isRefresh];
}

class SendTextMessageEvent extends ChatEvent {
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;

  SendTextMessageEvent({
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
  });

  @override
  List<Object?> get props => [chatRoomId, senderId, senderName, content];
}

class SendImageMessageEvent extends ChatEvent {
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final File imageFile;

  SendImageMessageEvent({
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [chatRoomId, senderId, senderName, imageFile];
}

class StartMessagesStreamEvent extends ChatEvent {
  final String chatRoomId;

  StartMessagesStreamEvent({required this.chatRoomId});

  @override
  List<Object?> get props => [chatRoomId];
}

class MessagesStreamUpdatedEvent extends ChatEvent {
  final List<ChatMessage> messages;

  MessagesStreamUpdatedEvent({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class DeleteMessageEvent extends ChatEvent {
  final String messageId;
  final String chatRoomId;

  DeleteMessageEvent({
    required this.messageId,
    required this.chatRoomId,
  });

  @override
  List<Object?> get props => [messageId, chatRoomId];
}

class PickImageEvent extends ChatEvent {
  final ImageSource source;

  PickImageEvent({required this.source});

  @override
  List<Object?> get props => [source];
}

class ImagePickedEvent extends ChatEvent {
  final File imageFile;

  ImagePickedEvent({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

class ClearPickedImageEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class MarkMessagesAsReadEvent extends ChatEvent {
  final String chatRoomId;
  final String userId;

  MarkMessagesAsReadEvent({
    required this.chatRoomId,
    required this.userId,
  });

  @override
  List<Object?> get props => [chatRoomId, userId];
}

class RetryLastActionEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class ClearErrorEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class NavigateBackToHomeEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}