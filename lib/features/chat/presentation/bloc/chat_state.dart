part of 'chat_bloc.dart';

@immutable
abstract class ChatState extends Equatable {}

class ChatInitial extends ChatState {
  @override
  List<Object?> get props => [];
}

class ChatRoomsLoadingState extends ChatState {
  @override
  List<Object?> get props => [];
}

class ChatRoomsSuccessState extends ChatState {
  final List<ChatRoom> chatRooms;
  final String? selectedChatRoomId;
  final bool isCreatingRoom;

  ChatRoomsSuccessState({
    required this.chatRooms,
    this.selectedChatRoomId,
    this.isCreatingRoom = false,
  });

  @override
  List<Object?> get props => [chatRooms, selectedChatRoomId, isCreatingRoom];

  ChatRoomsSuccessState copyWith({
    List<ChatRoom>? chatRooms,
    String? selectedChatRoomId,
    bool? isCreatingRoom,
    bool clearSelectedChatRoomId = false,
  }) {
    return ChatRoomsSuccessState(
      chatRooms: chatRooms ?? this.chatRooms,
      selectedChatRoomId: clearSelectedChatRoomId ? null : (selectedChatRoomId ?? this.selectedChatRoomId),
      isCreatingRoom: isCreatingRoom ?? this.isCreatingRoom,
    );
  }
}

class ChatRoomsFailureState extends ChatState {
  final String error;
  final bool canRetry;

  ChatRoomsFailureState({
    required this.error,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [error, canRetry];
}

class ChatRoomCreatedState extends ChatState {
  final ChatRoom chatRoom;

  ChatRoomCreatedState({required this.chatRoom});

  @override
  List<Object?> get props => [chatRoom];
}

class ChatRoomDeletedState extends ChatState {
  final String chatRoomId;

  ChatRoomDeletedState({required this.chatRoomId});

  @override
  List<Object?> get props => [chatRoomId];
}

class MessagesLoadingState extends ChatState {
  final String chatRoomId;

  MessagesLoadingState({required this.chatRoomId});

  @override
  List<Object?> get props => [chatRoomId];
}


class MessagesSuccessState extends ChatState {
  final String chatRoomId;
  final List<ChatMessage> messages;
  final bool isSendingMessage;
  final String? sendingMessageId;
  final ChatMessage? pendingMessage;
  final List<String> pendingMessageIds; 

  MessagesSuccessState({
    required this.chatRoomId,
    required this.messages,
    this.isSendingMessage = false,
    this.sendingMessageId,
    this.pendingMessage,
    this.pendingMessageIds = const [], 
  });

  @override
  List<Object?> get props => [
    chatRoomId, 
    messages, 
    isSendingMessage, 
    sendingMessageId, 
    pendingMessage,
    pendingMessageIds, 
  ];

  MessagesSuccessState copyWith({
    String? chatRoomId,
    List<ChatMessage>? messages,
    bool? isSendingMessage,
    String? sendingMessageId,
    ChatMessage? pendingMessage,
    List<String>? pendingMessageIds, 
    bool clearSendingMessageId = false,
    bool clearPendingMessage = false,
  }) {
    return MessagesSuccessState(
      chatRoomId: chatRoomId ?? this.chatRoomId,
      messages: messages ?? this.messages,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      sendingMessageId: clearSendingMessageId ? null : (sendingMessageId ?? this.sendingMessageId),
      pendingMessage: clearPendingMessage ? null : (pendingMessage ?? this.pendingMessage),
      pendingMessageIds: pendingMessageIds ?? this.pendingMessageIds, 
    );
  }
}

class MessagesFailureState extends ChatState {
  final String chatRoomId;
  final String error;
  final bool canRetry;

  MessagesFailureState({
    required this.chatRoomId,
    required this.error,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [chatRoomId, error, canRetry];
}

class MessageSendingState extends ChatState {
  final String chatRoomId;
  final ChatMessage pendingMessage;

  MessageSendingState({
    required this.chatRoomId,
    required this.pendingMessage,
  });

  @override
  List<Object?> get props => [chatRoomId, pendingMessage];
}

class MessageSentState extends ChatState {
  final ChatMessage sentMessage;

  MessageSentState({required this.sentMessage});

  @override
  List<Object?> get props => [sentMessage];
}

class MessageSendFailureState extends ChatState {
  final String chatRoomId;
  final String error;
  final ChatMessage? failedMessage;

  MessageSendFailureState({
    required this.chatRoomId,
    required this.error,
    this.failedMessage,
  });

  @override
  List<Object?> get props => [chatRoomId, error, failedMessage];
}

class ImagePickingState extends ChatState {
  @override
  List<Object?> get props => [];
}

class ImagePickedState extends ChatState {
  final File pickedImage;

  ImagePickedState({required this.pickedImage});

  @override
  List<Object?> get props => [pickedImage];
}

class ImageUploadingState extends ChatState {
  final File imageFile;
  final double? progress;

  ImageUploadingState({
    required this.imageFile,
    this.progress,
  });

  @override
  List<Object?> get props => [imageFile, progress];
}

class ImageUploadedState extends ChatState {
  final String imageUrl;

  ImageUploadedState({required this.imageUrl});

  @override
  List<Object?> get props => [imageUrl];
}

class ImageUploadFailureState extends ChatState {
  final String error;

  ImageUploadFailureState({required this.error});

  @override
  List<Object?> get props => [error];
}

class ChatActionSuccessState extends ChatState {
  final String message;
  final String action;

  ChatActionSuccessState({
    required this.message,
    required this.action,
  });

  @override
  List<Object?> get props => [message, action];
}

class ChatActionFailureState extends ChatState {
  final String error;
  final String action;

  ChatActionFailureState({
    required this.error,
    required this.action,
  });

  @override
  List<Object?> get props => [error, action];
}

class ImageReadyToSendState extends ChatState {
  final File imageFile;

  ImageReadyToSendState({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}