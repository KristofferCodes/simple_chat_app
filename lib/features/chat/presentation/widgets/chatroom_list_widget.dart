import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../main.dart';
import '../../data/models/chat_models.dart';

class ChatRoomListWidget extends StatelessWidget {
  final List<ChatRoom> chatRooms;
  final Function(ChatRoom) onChatRoomTapped;
  final Function(String) onChatRoomDeleted;
  final bool isLoading;

  const ChatRoomListWidget({
    Key? key,
    required this.chatRooms,
    required this.onChatRoomTapped,
    required this.onChatRoomDeleted,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmerLoading();
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: chatRooms.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        return _buildModernChatRoomTile(context, chatRoom);
      },
    );
  }

  Widget _buildModernChatRoomTile(BuildContext context, ChatRoom chatRoom) {
    final bool hasLastMessage = chatRoom.lastMessage != null;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChatRoomTapped(chatRoom),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getAvatarColor(chatRoom.name),
                        _getAvatarColor(chatRoom.name).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getAvatarColor(chatRoom.name).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      chatRoom.name.isNotEmpty ? chatRoom.name[0].toUpperCase() : '#',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chatRoom.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasLastMessage)
                            Text(
                              ChatHelpers.formatChatRoomTimestamp(chatRoom.lastMessage!.timestamp),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: 6),
                      
                      if (hasLastMessage) ...[
                        Row(
                          children: [
                            if (chatRoom.lastMessage!.type == MessageType.image)
                              Container(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.image,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            Expanded(
                              child: Text(
                                ChatHelpers.getMessagePreview(chatRoom.lastMessage!),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                      ],
                      
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${chatRoom.participantNames.length} participants',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                PopupMenuButton<String>(
                  icon: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onChatRoomDeleted(chatRoom.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red[600],
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete Room',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) => _buildShimmerItem(),
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                
                SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: 180,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 8),
                
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
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
    
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
}