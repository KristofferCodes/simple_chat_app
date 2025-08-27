import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../main.dart';
import '../../data/models/chat_models.dart';
import 'cached_img_widget.dart';
import 'message_shimmer_loader.dart';

class MessageListWidget extends StatelessWidget {
  final List<ChatMessage> messages;
  final List<String> pendingMessageIds; 
  final bool isLoading;
  final Function(String)? onMessageDeleted;

  const MessageListWidget({
    Key? key,
    required this.messages,
    this.pendingMessageIds = const [],
    this.isLoading = false,
    this.onMessageDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return _buildShimmerLoading();
    }

    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final isMe = message.senderId == AppConstants.defaultUserId;
        final showAvatar = _shouldShowAvatar(index, messages);
        final showTimestamp = _shouldShowTimestamp(index, messages);
        
        final bool isPending = message.isOptimistic || pendingMessageIds.contains(message.id);
        
        return _buildMessageBubbleWithLoading(
          context,
          message,
          isMe: isMe,
          showAvatar: showAvatar,
          showTimestamp: showTimestamp,
          isPending: isPending,
        );
      },
    );
  }

  Widget _buildMessageBubbleWithLoading(
    BuildContext context,
    ChatMessage message, {
    required bool isMe,
    required bool showAvatar,
    required bool showTimestamp,
    required bool isPending,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: showTimestamp ? 16 : 4,
        top: 4,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && showAvatar) _buildAvatar(message.senderName),
              if (!isMe && !showAvatar) SizedBox(width: 40),
              
              Flexible(
                child: GestureDetector(
                  onLongPress: () {
                    if (onMessageDeleted != null && isMe && !message.isOptimistic) {
                      _showDeleteDialog(context, message);
                    }
                  },
                  child: isPending 
                      ? _buildPendingMessage(message, isMe)
                      : _buildRegularMessage(context, message, isMe),
                ),
              ),
              
              if (isMe && showAvatar) _buildAvatar(message.senderName),
              if (isMe && !showAvatar) SizedBox(width: 40),
            ],
          ),
          
          if (showTimestamp && !isPending) _buildTimestamp(message, isMe),
        ],
      ),
    );
  }

  Widget _buildPendingMessage(ChatMessage message, bool isMe) {
    return PulsingMessageLoader(
      isPulsing: true,
      child: MessageShimmerLoader(
        isMe: isMe,
        isImageMessage: message.type == MessageType.image,
      ),
    );
  }

  Widget _buildRegularMessage(BuildContext context, ChatMessage message, bool isMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
        minWidth: 60,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: message.type == MessageType.image ? 4 : 16,
        vertical: message.type == MessageType.image ? 4 : 12,
      ),
      decoration: BoxDecoration(
        gradient: isMe ? _buildMyMessageGradient() : null,
        color: isMe ? null : Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: message.type == MessageType.text
          ? _buildTextMessage(message, isMe)
          : _buildImageMessage(message, isMe),
    );
  }

  Widget _buildTextMessage(ChatMessage message, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              message.senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getSenderColor(message.senderName),
              ),
            ),
          ),
        Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: isMe ? Colors.white : Colors.grey[800],
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage(ChatMessage message, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              message.senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getSenderColor(message.senderName),
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: message.imageUrl != null
              ? _buildImageDisplay(message.imageUrl!, isMe)
              : Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[200],
                  child: Icon(Icons.image, color: Colors.grey),
                ),
        ),
        if (message.content != 'Image')
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(String senderName) {
    return Container(
      width: 32,
      height: 32,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getSenderColor(senderName),
            _getSenderColor(senderName).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _getSenderColor(senderName).withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTimestamp(ChatMessage message, bool isMe) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        left: isMe ? 0 : 48,
        right: isMe ? 48 : 0,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ChatHelpers.formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isMe = index % 3 == 0;
        return _buildShimmerMessage(isMe);
      },
    );
  }

  Widget _buildShimmerMessage(bool isMe) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
          
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 200,
                minWidth: 80,
              ),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          
          if (isMe) ...[
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageDisplay(String imageUrl, bool isMe) {
    if (imageUrl.startsWith('cache:')) {
      return CachedImageWidget(
        imageUrl: imageUrl,
        width: 200,
        height: 150,
        fit: BoxFit.cover,
        placeholder: Container(
          width: 200,
          height: 150,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isMe ? Colors.white : Color(0xFF2196F3),
              ),
            ),
          ),
        ),
        errorWidget: Container(
          width: 200,
          height: 150,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, color: Colors.orange[400], size: 32),
              SizedBox(height: 8),
              Text(
                'Image expired',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 200,
        height: 150,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200,
          height: 150,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isMe ? Colors.white : Color(0xFF2196F3),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 150,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  LinearGradient _buildMyMessageGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2196F3),
        Color(0xFF1976D2),
      ],
    );
  }

  Color _getSenderColor(String senderName) {
    final colors = [
      Color(0xFF6C5CE7),
      Color(0xFF74B9FF),
      Color(0xFF00B894),
      Color(0xFFFF7675),
      Color(0xFFE17055),
      Color(0xFFFD79A8),
      Color(0xFF55A3FF),
      Color(0xFF26DE81),
    ];
    
    final index = senderName.hashCode.abs() % colors.length;
    return colors[index];
  }

  bool _shouldShowAvatar(int index, List<ChatMessage> messages) {
    if (messages.isEmpty) return true;
    
    final currentMessage = messages[messages.length - 1 - index];
    
    if (index == 0) return true;
    
    final nextMessage = messages[messages.length - index];
    return currentMessage.senderId != nextMessage.senderId;
  }

  bool _shouldShowTimestamp(int index, List<ChatMessage> messages) {
    if (messages.isEmpty) return true;
    
    final currentMessage = messages[messages.length - 1 - index];
    
    if (index % 5 == 0) return true;
    if (index == 0) return true;
    
    final nextMessage = messages[messages.length - index];
    return currentMessage.senderId != nextMessage.senderId;
  }

  void _showDeleteDialog(BuildContext context, ChatMessage message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[600],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Delete Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onMessageDeleted?.call(message.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}