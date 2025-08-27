import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../main.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/error_widget.dart';
import '../widgets/message_input_widget.dart';
import '../widgets/message_list_widget.dart';
import '../widgets/loading_widget.dart';
import '../../data/models/chat_models.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final ChatBloc chatBloc;

  const ChatRoomScreen({
    Key? key, 
    required this.chatRoom,
    required this.chatBloc,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  bool _isInitialLoading = true;
  String? _error;
  
  List<ChatMessage> _currentMessages = [];
  List<String> _currentPendingMessageIds = [];

  @override
  void initState() {
    super.initState();
    widget.chatBloc.add(FetchMessagesEvent(chatRoomId: widget.chatRoom.id));
    widget.chatBloc.add(StartMessagesStreamEvent(chatRoomId: widget.chatRoom.id));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.chatBloc.add(NavigateBackToHomeEvent());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chatRoom.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                '${widget.chatRoom.participantNames.length} participants',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                widget.chatBloc.add(
                  FetchMessagesEvent(chatRoomId: widget.chatRoom.id, isRefresh: true),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          bloc: widget.chatBloc,
          listener: (context, state) {
            log('ChatRoomScreen - State received: ${state.runtimeType}');
            
            if (state is MessagesLoadingState && state.chatRoomId == widget.chatRoom.id) {
              if (_currentMessages.isEmpty) {
                setState(() {
                  _isInitialLoading = true;
                  _error = null;
                });
                log('⏳ Showing loading state - no messages yet');
              } else {
                log('⏳ Loading state ignored - already have ${_currentMessages.length} messages');
              }
            }
            
            if (state is MessagesSuccessState && state.chatRoomId == widget.chatRoom.id) {
              setState(() {
                _isInitialLoading = false;
                _error = null;
                _currentMessages = List.from(state.messages); 
                _currentPendingMessageIds = List.from(state.pendingMessageIds);
              });
              log('✅ Updated local state: ${_currentMessages.length} messages, ${_currentPendingMessageIds.length} pending');
            }
            
            if (state is MessagesFailureState && state.chatRoomId == widget.chatRoom.id) {
              setState(() {
                _isInitialLoading = false;
                _error = state.error;
              });
              log('❌ Error state: ${state.error}');
            }

            if (state is MessageSendFailureState) {
              _showErrorMessage(context, 'Failed to send message: ${state.error}');
            }

            if (state is ImageReadyToSendState) {
              _handleImagePicked(state.imageFile);
            }

            if (state is ImageUploadFailureState) {
  _showErrorMessage(context, state.error);
}

            if (state is ChatRoomsSuccessState) {
              log('🏠 Ignoring ChatRoomsSuccessState to preserve messages');
            }
            if (state is ChatActionSuccessState) {
              log('🎯 Ignoring ChatActionSuccessState to preserve messages');
            }
          },
          builder: (context, state) {
            return _buildBody();
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    log('🏗️ _buildBody called - _currentMessages.length: ${_currentMessages.length}, _isInitialLoading: $_isInitialLoading');
    if (_isInitialLoading && _currentMessages.isEmpty) {
      log('🔄 Showing loading widget');
      return ChatLoadingWidget();
    }
    
    if (_error != null && _currentMessages.isEmpty) {
      log('❌ Showing error widget: $_error');
      return ChatErrorWidget(
        message: _error!,
        onRetry: () {
          widget.chatBloc.add(FetchMessagesEvent(chatRoomId: widget.chatRoom.id));
        },
      );
    }

    log('💬 Showing messages: ${_currentMessages.length} total, ${_currentPendingMessageIds.length} pending');
    
    return Column(
      children: [
        Expanded(
          child: MessageListWidget(
            messages: _currentMessages,
            pendingMessageIds: _currentPendingMessageIds,
            isLoading: false,
            onMessageDeleted: (messageId) {
              _showDeleteMessageConfirmation(context, messageId);
            },
          ),
        ),
        MessageInputWidget(
          onTextMessageSent: (content) {
            _sendTextMessage(content);
          },
          onImageMessageSent: () {
            _showImageSourceSelection(context);
          },
          isLoading: false,
        ),
      ],
    );
  }

  void _sendTextMessage(String content) {
    if (content.trim().isEmpty) return;
    
    log('📤 Sending text message: ${content.trim()}');

    widget.chatBloc.add(
      SendTextMessageEvent(
        chatRoomId: widget.chatRoom.id,
        senderId: AppConstants.defaultUserId,
        senderName: AppConstants.defaultUserName,
        content: content.trim(),
      ),
    );
  }

  void _handleImagePicked(File imageFile) {
    log('📷 Image picked, sending through BLoC');

    widget.chatBloc.add(
      SendImageMessageEvent(
        chatRoomId: widget.chatRoom.id,
        senderId: AppConstants.defaultUserId,
        senderName: AppConstants.defaultUserName,
        imageFile: imageFile,
      ),
    );
  }

  void _showImageSourceSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                widget.chatBloc.add(PickImageEvent(source: ImageSource.camera));
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                widget.chatBloc.add(PickImageEvent(source: ImageSource.gallery));
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteMessageConfirmation(BuildContext context, String messageId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.chatBloc.add(
                DeleteMessageEvent(messageId: messageId, chatRoomId: widget.chatRoom.id),
              );
              log('🗑️ Requested message deletion: $messageId');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}