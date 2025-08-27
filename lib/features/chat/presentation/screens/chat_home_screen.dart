import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chatroom_list_widget.dart';
import '../widgets/create_chatroom_dialog.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../../data/models/chat_models.dart';
import '../../data/repository/firebase_chat_repository.dart';
import '../../domain/repository/chat_repository.dart';
import 'chat_room_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    final ChatRepository repository = FirebaseChatRepository();
    _chatBloc = ChatBloc(repository)
      ..add(FetchChatRoomsEvent())
      ..add(StartChatRoomsStreamEvent());
  }

  @override
  void dispose() {
    _chatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _chatBloc.add(FetchChatRoomsEvent(isRefresh: true));
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        bloc: _chatBloc,
        listener: (context, state) {
          if (state is ChatRoomCreatedState) {
            _showSuccessMessage(context, 'Chat room created successfully!');
            _navigateToChatRoom(context, state.chatRoom);
          }
          
          if (state is ChatActionFailureState) {
            _showErrorMessage(context, state.error);
          }
          
          if (state is ChatRoomDeletedState) {
            _showSuccessMessage(context, 'Chat room deleted successfully!');
          }
        },
        builder: (context, state) {
          if (state is ChatRoomsLoadingState) {
            return ChatLoadingWidget();
          }
          
          if (state is ChatRoomsFailureState) {
            return ChatErrorWidget(
              message: state.error,
              onRetry: () {
                _chatBloc.add(FetchChatRoomsEvent());
              },
            );
          }
          
          if (state is ChatRoomsSuccessState) {
            return _buildChatRoomsList(context, state);
          }
          
          return ChatLoadingWidget();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatRoomDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Create New Chat Room',
      ),
    );
  }

  Widget _buildChatRoomsList(BuildContext context, ChatRoomsSuccessState state) {
    if (state.chatRooms.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        _chatBloc.add(FetchChatRoomsEvent(isRefresh: true));
      },
      child: Column(
        children: [
          if (state.isCreatingRoom)
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating chat room...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ChatRoomListWidget(
              chatRooms: state.chatRooms,
              onChatRoomTapped: (chatRoom) {
                _navigateToChatRoom(context, chatRoom);
              },
              onChatRoomDeleted: (chatRoomId) {
                _showDeleteConfirmation(context, chatRoomId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'No Chat Rooms Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Create your first chat room to start chatting with others!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateChatRoomDialog(context),
              icon: Icon(Icons.add),
              label: Text('Create Chat Room'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChatRoom(BuildContext context, ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatRoom: chatRoom, 
          chatBloc: _chatBloc,  
        ),
      ),
    );
  }

  void _showCreateChatRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => CreateChatRoomDialog(
        chatBloc: _chatBloc,  
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String chatRoomId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Chat Room'),
        content: Text('Are you sure you want to delete this chat room? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _chatBloc.add(DeleteChatRoomEvent(chatRoomId: chatRoomId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}