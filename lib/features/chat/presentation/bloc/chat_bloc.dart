import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/chat_models.dart';
import '../../domain/repository/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  final ImagePicker _imagePicker = ImagePicker();
  
  int _retryCount = 0;
  static const int maxRetries = 3;
  ChatEvent? _lastFailedEvent;

  String? _currentChatRoomId;
  
  final Map<String, ChatMessage> _pendingMessages = {};

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<ChatEvent>((event, emit) {
      log('📨 BLoC Event: ${event.runtimeType}');
    if (event is FetchMessagesEvent) {
      log('  🔄 FetchMessagesEvent - chatRoomId: ${event.chatRoomId}, isRefresh: ${event.isRefresh}');
      log('  📊 Current state: ${state.runtimeType}');
      log('  📍 Stack trace: ${StackTrace.current}');
    }
    });

    on<FetchChatRoomsEvent>(_mapFetchChatRoomsEventToState);
    on<CreateChatRoomEvent>(_mapCreateChatRoomEventToState);
    on<SelectChatRoomEvent>(_mapSelectChatRoomEventToState);
    on<StartChatRoomsStreamEvent>(_mapStartChatRoomsStreamEventToState);
    on<ChatRoomsStreamUpdatedEvent>(_mapChatRoomsStreamUpdatedEventToState);
    on<DeleteChatRoomEvent>(_mapDeleteChatRoomEventToState);

    on<FetchMessagesEvent>(_mapFetchMessagesEventToState);
    on<SendTextMessageEvent>(_mapSendTextMessageEventToState);
    on<SendImageMessageEvent>(_mapSendImageMessageEventToState);
    on<StartMessagesStreamEvent>(_mapStartMessagesStreamEventToState);
    on<MessagesStreamUpdatedEvent>(_mapMessagesStreamUpdatedEventToState);
    on<DeleteMessageEvent>(_mapDeleteMessageEventToState);

    on<PickImageEvent>(_mapPickImageEventToState);
    on<ImagePickedEvent>(_mapImagePickedEventToState);
    on<ClearPickedImageEvent>(_mapClearPickedImageEventToState);

    on<MarkMessagesAsReadEvent>(_mapMarkMessagesAsReadEventToState);
    on<RetryLastActionEvent>(_mapRetryLastActionEventToState);
    on<ClearErrorEvent>(_mapClearErrorEventToState);
    on<NavigateBackToHomeEvent>(_mapNavigateBackToHomeEventToState);
  }

  FutureOr<void> _mapNavigateBackToHomeEventToState(
      NavigateBackToHomeEvent event, Emitter<ChatState> emit) async {
    try {
      await _messagesSubscription?.cancel();
      _messagesSubscription = null;
      _currentChatRoomId = null;
      _pendingMessages.clear();

      final List<ChatRoom> chatRooms = await _repository.fetchChatRooms();
      emit(ChatRoomsSuccessState(chatRooms: chatRooms));
    } catch (e) {
      log('Error navigating back to home: $e');
      emit(ChatRoomsFailureState(error: e.toString()));
    }
  }

  FutureOr<void> _mapFetchChatRoomsEventToState(
      FetchChatRoomsEvent event, Emitter<ChatState> emit) async {
    try {
      if (event.isRefresh || !(state is ChatRoomsSuccessState)) {
        emit(ChatRoomsLoadingState());
      }

      final List<ChatRoom> chatRooms = await _repository.fetchChatRooms();
      _retryCount = 0;

      emit(ChatRoomsSuccessState(chatRooms: chatRooms));
    } catch (e, stack) {
      log('Error fetching chat rooms: $e');
      log('Stack trace: $stack');

      if (_shouldRetry(e) && _retryCount < maxRetries) {
        _retryCount++;
        _lastFailedEvent = event;
        await Future.delayed(Duration(seconds: _retryCount * 2));
        add(FetchChatRoomsEvent(isRefresh: event.isRefresh));
      } else {
        _retryCount = 0;
        emit(ChatRoomsFailureState(error: e.toString()));
      }
    }
  }

  FutureOr<void> _mapCreateChatRoomEventToState(
      CreateChatRoomEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    
    if (currentState is ChatRoomsSuccessState) {
      emit(currentState.copyWith(isCreatingRoom: true));
    }

    try {
      final ChatRoom newChatRoom = await _repository.createChatRoom(
        event.name,
        event.participantNames,
      );

      emit(ChatRoomCreatedState(chatRoom: newChatRoom));
      
      add(FetchChatRoomsEvent(isRefresh: true));
    } catch (e, stack) {
      log('Error creating chat room: $e');
      log('Stack trace: $stack');

      if (currentState is ChatRoomsSuccessState) {
        emit(currentState.copyWith(isCreatingRoom: false));
      }

      emit(ChatActionFailureState(
        error: 'Failed to create chat room: ${e.toString()}',
        action: 'create_room',
      ));

      if (currentState is ChatRoomsSuccessState) {
        emit(currentState);
      }
    }
  }

  FutureOr<void> _mapSelectChatRoomEventToState(
      SelectChatRoomEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    
    if (currentState is ChatRoomsSuccessState) {
      emit(currentState.copyWith(selectedChatRoomId: event.chatRoomId));
    }
  }

  FutureOr<void> _mapStartChatRoomsStreamEventToState(
      StartChatRoomsStreamEvent event, Emitter<ChatState> emit) async {
    try {
      await _chatRoomsSubscription?.cancel();
      _chatRoomsSubscription = _repository.getChatRoomsStream().listen(
        (chatRooms) {
          add(ChatRoomsStreamUpdatedEvent(chatRooms: chatRooms));
        },
        onError: (error) {
          log('Chat rooms stream error: $error');
          emit(ChatRoomsFailureState(error: error.toString()));
        },
      );
    } catch (e, stack) {
      log('Error starting chat rooms stream: $e');
      log('Stack trace: $stack');
      emit(ChatRoomsFailureState(error: e.toString()));
    }
  }

  FutureOr<void> _mapChatRoomsStreamUpdatedEventToState(
      ChatRoomsStreamUpdatedEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    
    if (currentState is ChatRoomsSuccessState) {
      emit(currentState.copyWith(chatRooms: event.chatRooms));
    } else {
      emit(ChatRoomsSuccessState(chatRooms: event.chatRooms));
    }
  }

  FutureOr<void> _mapDeleteChatRoomEventToState(
      DeleteChatRoomEvent event, Emitter<ChatState> emit) async {
    try {
      await _repository.deleteChatRoom(event.chatRoomId);
      
      emit(ChatRoomDeletedState(chatRoomId: event.chatRoomId));
      
      add(FetchChatRoomsEvent(isRefresh: true));
    } catch (e, stack) {
      log('Error deleting chat room: $e');
      log('Stack trace: $stack');
      
      emit(ChatActionFailureState(
        error: 'Failed to delete chat room: ${e.toString()}',
        action: 'delete_room',
      ));
    }
  }

  FutureOr<void> _mapFetchMessagesEventToState(
      FetchMessagesEvent event, Emitter<ChatState> emit) async {
    try {
      _currentChatRoomId = event.chatRoomId;
      
        log('🔍 Processing FetchMessagesEvent:');
    log('  - chatRoomId: ${event.chatRoomId}');
    log('  - isRefresh: ${event.isRefresh}');
    log('  - current state: ${state.runtimeType}');
    
    if (event.isRefresh || state is! MessagesSuccessState) {
      log('  ⏳ Emitting MessagesLoadingState');
      emit(MessagesLoadingState(chatRoomId: event.chatRoomId));
    } else {
      log('  ✅ Skipping loading state - already have MessagesSuccessState');
    }

    final List<ChatMessage> messages = await _repository.fetchMessages(event.chatRoomId);
    _retryCount = 0;

    log('  📨 Emitting MessagesSuccessState with ${messages.length} messages');
    emit(MessagesSuccessState(
      chatRoomId: event.chatRoomId,
      messages: messages,
      pendingMessageIds: _pendingMessages.keys.toList(),
    ));
    } catch (e, stack) {
      log('Error fetching messages: $e');
      log('Stack trace: $stack');

      if (_shouldRetry(e) && _retryCount < maxRetries) {
        _retryCount++;
        _lastFailedEvent = event;
        await Future.delayed(Duration(seconds: _retryCount * 2));
        add(FetchMessagesEvent(chatRoomId: event.chatRoomId, isRefresh: event.isRefresh));
      } else {
        _retryCount = 0;
        emit(MessagesFailureState(
          chatRoomId: event.chatRoomId,
          error: e.toString(),
        ));
      }
    }
  }

 
FutureOr<void> _mapSendTextMessageEventToState(
    SendTextMessageEvent event, Emitter<ChatState> emit) async {
  final currentState = state;
  
  if (currentState is! MessagesSuccessState || 
      currentState.chatRoomId != event.chatRoomId) {
    log('Cannot send message - not in correct state');
    return;
  }

  final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  final optimisticMessage = ChatMessage(
    id: tempId,
    chatRoomId: event.chatRoomId,
    senderId: event.senderId,
    senderName: event.senderName,
    content: event.content,
    type: MessageType.text,
    timestamp: DateTime.now(),
    isOptimistic: true,
  );

  _pendingMessages[tempId] = optimisticMessage;

  final updatedMessages = [...currentState.messages, optimisticMessage];
  
  log('Adding optimistic message: $tempId');
  emit(currentState.copyWith(
    messages: updatedMessages,
    pendingMessageIds: _pendingMessages.keys.toList(),
  ));

  try {
    final SendMessageResponse response = await _repository.sendTextMessage(
      event.chatRoomId,
      event.senderId,
      event.senderName,
      event.content,
    );

    if (response.success) {
      log('Message sent successfully: ${response.message.id}');

      Future.delayed(Duration(milliseconds: 500), () {
    add(FetchMessagesEvent(chatRoomId: event.chatRoomId, isRefresh: true));
  });
      
      _pendingMessages[tempId] = optimisticMessage.copyWith(
        isOptimistic: false, 
        id: response.message.id, 
      );
      
      emit(currentState.copyWith(
        messages: currentState.messages, 
        pendingMessageIds: [], 
      ));
      
      log('Optimistic message marked as sent, waiting for stream confirmation');
      
    } else {
      throw Exception(response.error ?? 'Failed to send message');
    }
  } catch (e, stack) {
    log('Error sending text message: $e');
    
    _pendingMessages.remove(tempId);
    final messagesWithoutFailed = currentState.messages
        .where((msg) => msg.id != tempId)
        .toList();

    emit(currentState.copyWith(
      messages: messagesWithoutFailed,
      pendingMessageIds: _pendingMessages.keys.toList(),
    ));

    emit(MessageSendFailureState(
      chatRoomId: event.chatRoomId,
      error: e.toString(),
      failedMessage: optimisticMessage,
    ));
  }
}

FutureOr<void> _mapSendImageMessageEventToState(
    SendImageMessageEvent event, Emitter<ChatState> emit) async {
  final currentState = state;
  
  MessagesSuccessState? messagesState;
  
  if (currentState is MessagesSuccessState && currentState.chatRoomId == event.chatRoomId) {
    messagesState = currentState;
  } else if (currentState is ImageReadyToSendState) {  
    log('Image send from ImageReadyToSendState - fetching current messages');
    try {
      final messages = await _repository.fetchMessages(event.chatRoomId);
      messagesState = MessagesSuccessState(
        chatRoomId: event.chatRoomId,
        messages: messages,
        pendingMessageIds: _pendingMessages.keys.toList(),
      );
    } catch (e) {
      log('Failed to fetch messages for image send: $e');
      emit(MessageSendFailureState(
        chatRoomId: event.chatRoomId,
        error: 'Failed to get current messages: $e',
        failedMessage: null,
      ));
      return;
    }
  } else {
    log('Cannot send image message - not in correct state: ${currentState.runtimeType}');
    return;
  }

  final String tempId = 'temp_img_${DateTime.now().millisecondsSinceEpoch}';
  final optimisticMessage = ChatMessage(
    id: tempId,
    chatRoomId: event.chatRoomId,
    senderId: event.senderId,
    senderName: event.senderName,
    content: 'Sending image...',
    type: MessageType.image,
    timestamp: DateTime.now(),
    imageUrl: event.imageFile.path, 
    isOptimistic: true, 
  );

  final updatedMessages = [...messagesState.messages, optimisticMessage];
  _pendingMessages[tempId] = optimisticMessage;
  
  emit(MessagesSuccessState(
    chatRoomId: event.chatRoomId,
    messages: updatedMessages,
    pendingMessageIds: _pendingMessages.keys.toList(),
  ));

  try {
    final SendMessageResponse response = await _repository.sendImageMessage(
      event.chatRoomId,
      event.senderId,
      event.senderName,
      event.imageFile,
    );

    if (response.success) {
      log('Image message sent successfully: ${response.message.id}');
      
      Future.delayed(Duration(milliseconds: 500), () {
        add(FetchMessagesEvent(chatRoomId: event.chatRoomId, isRefresh: true));
      });
      
      _pendingMessages.remove(tempId);
      
      emit(MessageSentState(sentMessage: response.message));
      
      final messagesWithoutOptimistic = messagesState!.messages
          .where((msg) => msg.id != tempId)
          .toList();
      
      emit(MessagesSuccessState(
        chatRoomId: event.chatRoomId,
        messages: messagesWithoutOptimistic,
        pendingMessageIds: _pendingMessages.keys.toList(),
      ));
    } else {
      throw Exception(response.error ?? 'Failed to send image');
    }
  } catch (e, stack) {
    log('Error sending image message: $e');
    log('Stack trace: $stack');

    _pendingMessages.remove(tempId);
    final messagesWithoutOptimistic = messagesState!.messages
        .where((msg) => msg.id != tempId)
        .toList();

    emit(MessagesSuccessState(
      chatRoomId: event.chatRoomId,
      messages: messagesWithoutOptimistic,
      pendingMessageIds: _pendingMessages.keys.toList(),
    ));

    emit(MessageSendFailureState(
      chatRoomId: event.chatRoomId,
      error: e.toString(),
      failedMessage: optimisticMessage,
    ));
  }
}

  FutureOr<void> _mapStartMessagesStreamEventToState(
      StartMessagesStreamEvent event, Emitter<ChatState> emit) async {
    try {
      _currentChatRoomId = event.chatRoomId;
      
      await _messagesSubscription?.cancel();
      _messagesSubscription = _repository.getMessagesStream(event.chatRoomId).listen(
        (messages) {
          if (_currentChatRoomId == event.chatRoomId) {
            add(MessagesStreamUpdatedEvent(messages: messages));
          }
        },
        onError: (error) {
          log('Messages stream error: $error');
          if (_currentChatRoomId == event.chatRoomId) {
            emit(MessagesFailureState(
              chatRoomId: event.chatRoomId,
              error: error.toString(),
            ));
          }
        },
      );
    } catch (e, stack) {
      log('Error starting messages stream: $e');
      log('Stack trace: $stack');
      emit(MessagesFailureState(
        chatRoomId: event.chatRoomId,
        error: e.toString(),
      ));
    }
  }

  FutureOr<void> _mapMessagesStreamUpdatedEventToState(
    MessagesStreamUpdatedEvent event, Emitter<ChatState> emit) async {
  final currentState = state;
  
  if (currentState is MessagesSuccessState && 
      _currentChatRoomId == currentState.chatRoomId) {
    
    final List<ChatMessage> allMessages = [...event.messages];
    
    for (final pendingMessage in _pendingMessages.values) {
      final bool alreadyExists = allMessages.any((msg) => 
          msg.content.trim() == pendingMessage.content.trim() && 
          msg.senderId == pendingMessage.senderId &&
          msg.timestamp.difference(pendingMessage.timestamp).abs().inSeconds < 10);
      
      if (!alreadyExists) {
        allMessages.add(pendingMessage);
      } else {
        _pendingMessages.remove(pendingMessage.id);
      }
    }
    
    allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    emit(currentState.copyWith(
      messages: allMessages,
      pendingMessageIds: _pendingMessages.keys.toList(),
    ));
  } else if (currentState is MessagesLoadingState && 
             _currentChatRoomId == currentState.chatRoomId) {
    emit(MessagesSuccessState(
      chatRoomId: currentState.chatRoomId,
      messages: event.messages,
    ));
  }
}

  FutureOr<void> _mapDeleteMessageEventToState(
      DeleteMessageEvent event, Emitter<ChatState> emit) async {
    try {
      await _repository.deleteMessage(event.messageId, event.chatRoomId);
      
      emit(ChatActionSuccessState(
        message: 'Message deleted successfully',
        action: 'delete_message',
      ));
    } catch (e, stack) {
      log('Error deleting message: $e');
      log('Stack trace: $stack');
      
      emit(ChatActionFailureState(
        error: 'Failed to delete message: ${e.toString()}',
        action: 'delete_message',
      ));
    }
  }

FutureOr<void> _mapPickImageEventToState(
    PickImageEvent event, Emitter<ChatState> emit) async {
  try {
    log('Starting image picker with source: ${event.source}');
    
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: event.source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.rear,
    );
    
    if (pickedFile != null) {
      log('Image picked: ${pickedFile.path}, name: ${pickedFile.name}');
      
      try {
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        log('Successfully read ${imageBytes.length} bytes from picked image');
        
        if (imageBytes.isEmpty) {
          throw Exception('Image file is empty');
        }
        
        final Directory tempDir = await getTemporaryDirectory();
        final String fileName = 'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File tempFile = File('${tempDir.path}/$fileName');
        
        await tempFile.writeAsBytes(imageBytes);
        log('Copied image to temp file: ${tempFile.path}');
        
        if (await tempFile.exists()) {
          final int fileSize = await tempFile.length();
          log('Temp file size: $fileSize bytes');
          
          if (fileSize > 0) {
            add(ImagePickedEvent(imageFile: tempFile));
          } else {
            throw Exception('Temporary image file is empty');
          }
        } else {
          throw Exception('Failed to create temporary image file');
        }
        
      } catch (fileError) {
        log('Error processing picked file: $fileError');
        
        try {
          final File originalFile = File(pickedFile.path);
          if (await originalFile.exists()) {
            final int fileSize = await originalFile.length();
            if (fileSize > 0) {
              log('Using original file path as fallback');
              add(ImagePickedEvent(imageFile: originalFile));
              return;
            }
          }
        } catch (fallbackError) {
          log('Fallback also failed: $fallbackError');
        }
        
        throw Exception('Cannot access selected image file: $fileError');
      }
    } else {
      log('Image picker cancelled by user');
    }
  } catch (e, stack) {
    log('Error picking image: $e');
    log('Stack trace: $stack');
    
    String errorMessage;
    if (e.toString().contains('no_valid_image_uri')) {
      errorMessage = 'Cannot access the selected image. Try selecting a different image or restarting the app.';
    } else if (e.toString().contains('permission')) {
      errorMessage = 'Camera/storage permission required. Please grant permission in device settings.';
    } else if (e.toString().contains('camera')) {
      errorMessage = 'Camera is not available. Please try gallery instead.';
    } else if (e.toString().contains('cancelled')) {
      log('Image picker was cancelled');
      return; 
    } else {
      errorMessage = 'Failed to pick image. Please try again or select a different image.';
    }
    
    emit(ImageUploadFailureState(error: errorMessage));
  }
}

  FutureOr<void> _mapImagePickedEventToState(
      ImagePickedEvent event, Emitter<ChatState> emit) async {
    emit(ImageReadyToSendState(imageFile: event.imageFile));
  }

  FutureOr<void> _mapClearPickedImageEventToState(
      ClearPickedImageEvent event, Emitter<ChatState> emit) async {
    if (state is ImagePickedState) {
      emit(ChatInitial());
    }
  }

  FutureOr<void> _mapMarkMessagesAsReadEventToState(
      MarkMessagesAsReadEvent event, Emitter<ChatState> emit) async {
    try {
      await _repository.markMessagesAsRead(event.chatRoomId, event.userId);
    } catch (e, stack) {
      log('Error marking messages as read: $e');
      log('Stack trace: $stack');
    }
  }

  FutureOr<void> _mapRetryLastActionEventToState(
      RetryLastActionEvent event, Emitter<ChatState> emit) async {
    if (_lastFailedEvent != null) {
      _retryCount = 0;
      add(_lastFailedEvent!);
      _lastFailedEvent = null;
    }
  }

  FutureOr<void> _mapClearErrorEventToState(
      ClearErrorEvent event, Emitter<ChatState> emit) async {
    if (state is ChatRoomsFailureState) {
      add(FetchChatRoomsEvent());
    } else if (state is MessagesFailureState) {
      final messagesState = state as MessagesFailureState;
      add(FetchMessagesEvent(chatRoomId: messagesState.chatRoomId));
    }
  }

  bool _shouldRetry(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('network') ||
           errorString.contains('firebase');
  }

  @override
  Future<void> close() {
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _pendingMessages.clear();
    return super.close();
  }
}