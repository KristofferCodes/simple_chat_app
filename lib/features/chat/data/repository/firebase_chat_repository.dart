import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../../domain/repository/chat_repository.dart';
import '../models/chat_models.dart';

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static final Map<String, String> _imageCache = <String, String>{};
  static final Map<String, DateTime> _imageCacheTimestamps = <String, DateTime>{};
  
  static const Duration _cacheExpiry = Duration(hours: 24);

  static const String chatRoomsCollection = 'chat_rooms';
  static const String messagesCollection = 'messages';
  static const String imagesCollection = 'images'; 

  @override
  Future<List<ChatRoom>> fetchChatRooms() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(chatRoomsCollection)
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .get();

      log('Firestore read count: ${querySnapshot.docs.length} chat rooms');
      
      return querySnapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      log('Error fetching chat rooms: $e');
      log('Stack trace: $stack');
      rethrow;
    }
  }

  @override
  Stream<List<ChatRoom>> getChatRoomsStream() {
    try {
      return _firestore
          .collection(chatRoomsCollection)
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) {
            log('Firestore stream read count: ${snapshot.docs.length} chat rooms');
            return snapshot.docs
                .map((doc) => ChatRoom.fromFirestore(doc.data()))
                .toList();
          });
    } catch (e, stack) {
      log('Error getting chat rooms stream: $e');
      log('Stack trace: $stack');
      rethrow;
    }
  }

  @override
  Future<ChatRoom> createChatRoom(String name, List<String> participantNames) async {
    try {
      final String chatRoomId = _uuid.v4();
      final DateTime now = DateTime.now();

      final ChatRoom chatRoom = ChatRoom(
        id: chatRoomId,
        name: name,
        participantIds: [],
        participantNames: participantNames,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(chatRoomsCollection)
          .doc(chatRoomId)
          .set(chatRoom.toFirestore());

      log('Chat room created - 1 write used');
      return chatRoom;
    } catch (e, stack) {
      log('Error creating chat room: $e');
      log('Stack trace: $stack');
      rethrow;
    }
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String chatRoomId, {int limit = 30}) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      log('Firestore read count: ${querySnapshot.docs.length} messages for room $chatRoomId');

      final List<ChatMessage> messages = querySnapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      return messages.reversed.toList();
    } catch (e, stack) {
      log('Error fetching messages: $e');
      log('Stack trace: $stack');
      rethrow;
    }
  }

  @override
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    try {
      return _firestore
          .collection(messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .orderBy('timestamp', descending: false)
          .limit(50)
          .snapshots()
          .map((snapshot) {
            log('Firestore stream read count: ${snapshot.docs.length} messages for room $chatRoomId');
            return snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc.data()))
                .toList();
          });
    } catch (e, stack) {
      log('Error getting messages stream: $e');
      log('Stack trace: $stack');
      rethrow;
    }
  }

  @override
  Future<SendMessageResponse> sendTextMessage(
      String chatRoomId, String senderId, String senderName, String content) async {
    try {
      final String messageId = _uuid.v4();
      final DateTime now = DateTime.now();

      final ChatMessage message = ChatMessage(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: MessageType.text,
        timestamp: now,
      );

      final WriteBatch batch = _firestore.batch();

      final DocumentReference messageRef = _firestore.collection(messagesCollection).doc(messageId);
      batch.set(messageRef, message.toFirestore());

      final DocumentReference chatRoomRef = _firestore.collection(chatRoomsCollection).doc(chatRoomId);
      batch.update(chatRoomRef, {
        'lastMessage': message.toFirestore(),
        'updatedAt': Timestamp.fromDate(now),
      });

      await batch.commit();
      log('Text message sent - 2 writes used (message + chat room update)');

      return SendMessageResponse(message: message, success: true);
    } catch (e, stack) {
      log('Error sending text message: $e');
      log('Stack trace: $stack');
      return SendMessageResponse(
        message: ChatMessage(
          id: '',
          chatRoomId: chatRoomId,
          senderId: senderId,
          senderName: senderName,
          content: content,
          type: MessageType.text,
          timestamp: DateTime.now(),
        ),
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<SendMessageResponse> sendImageMessages(
      String chatRoomId, String senderId, String senderName, File imageFile) async {
    try {
      final compressedResult = await _compressAndEncodeImage(imageFile);
      if (!compressedResult['success']) {
        return SendMessageResponse(
          message: ChatMessage(
            id: '',
            chatRoomId: chatRoomId,
            senderId: senderId,
            senderName: senderName,
            content: 'Image processing failed',
            type: MessageType.image,
            timestamp: DateTime.now(),
          ),
          success: false,
          error: compressedResult['error'],
        );
      }

      final imageId = _uuid.v4();
      await _firestore.collection(imagesCollection).doc(imageId).set({
        'imageData': compressedResult['base64'],
        'contentType': compressedResult['contentType'],
        'uploadedAt': Timestamp.now(),
        'chatRoomId': chatRoomId,
      });

      final String messageId = _uuid.v4();
      final DateTime now = DateTime.now();

      final ChatMessage message = ChatMessage(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        content: 'Image',
        type: MessageType.image,
        timestamp: now,
        imageUrl: 'firestore:$imageId', 
      );

      final WriteBatch batch = _firestore.batch();

      final DocumentReference messageRef = _firestore.collection(messagesCollection).doc(messageId);
      batch.set(messageRef, message.toFirestore());

      final DocumentReference chatRoomRef = _firestore.collection(chatRoomsCollection).doc(chatRoomId);
      batch.update(chatRoomRef, {
        'lastMessage': message.toFirestore(),
        'updatedAt': Timestamp.fromDate(now),
      });

      await batch.commit();
      log('Image message sent - 3 writes used (image + message + chat room update)');

      return SendMessageResponse(message: message, success: true);
    } catch (e, stack) {
      log('Error sending image message: $e');
      log('Stack trace: $stack');
      return SendMessageResponse(
        message: ChatMessage(
          id: '',
          chatRoomId: chatRoomId,
          senderId: senderId,
          senderName: senderName,
          content: 'Failed to send image',
          type: MessageType.image,
          timestamp: DateTime.now(),
        ),
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _compressAndEncodeImage(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      if (imageBytes.length > 1024 * 1024) { 
        img.Image? image = img.decodeImage(imageBytes);
        if (image == null) {
          return {
            'success': false,
            'error': 'Invalid image format',
          };
        }

        img.Image resized = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 800 : null,
        );

        final Uint8List compressedBytes = img.encodeJpg(resized, quality: 70);
        
        if (compressedBytes.length > 800 * 1024) { 
          return {
            'success': false,
            'error': 'Image too large even after compression. Please use a smaller image.',
          };
        }

        final String base64String = base64Encode(compressedBytes);
        return {
          'success': true,
          'base64': base64String,
          'contentType': 'image/jpeg',
        };
      } else {
        final String base64String = base64Encode(imageBytes);
        final String contentType = _getContentType(imageFile.path);
        return {
          'success': true,
          'base64': base64String,
          'contentType': contentType,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to process image: $e',
      };
    }
  }

  Future<String?> getImageBase64(String imageId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(imagesCollection)
          .doc(imageId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['imageData'] as String?;
      }
      return null;
    } catch (e) {
      log('Error retrieving image: $e');
      return null;
    }
  }

  @override
  Future<UploadImageResponse> uploadImages(File imageFile) async {
    try {
      final compressedResult = await _compressAndEncodeImage(imageFile);
      if (compressedResult['success']) {
        final imageId = _uuid.v4();
        await _firestore.collection(imagesCollection).doc(imageId).set({
          'imageData': compressedResult['base64'],
          'contentType': compressedResult['contentType'],
          'uploadedAt': Timestamp.now(),
        });
        
        return UploadImageResponse(
          imageUrl: 'firestore:$imageId',
          success: true,
        );
      } else {
        return UploadImageResponse(
          imageUrl: '',
          success: false,
          error: compressedResult['error'],
        );
      }
    } catch (e) {
      return UploadImageResponse(
        imageUrl: '',
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<SendMessageResponse> sendImageMessage(
      String chatRoomId, String senderId, String senderName, File imageFile) async {
    try {
      final cacheResult = await _cacheImageLocally(imageFile);
      if (!cacheResult['success']) {
        return SendMessageResponse(
          message: ChatMessage(
            id: '',
            chatRoomId: chatRoomId,
            senderId: senderId,
            senderName: senderName,
            content: 'Image processing failed',
            type: MessageType.image,
            timestamp: DateTime.now(),
          ),
          success: false,
          error: cacheResult['error'],
        );
      }

      final String messageId = _uuid.v4();
      final DateTime now = DateTime.now();

      final ChatMessage message = ChatMessage(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        content: 'Image',
        type: MessageType.image,
        timestamp: now,
        imageUrl: 'cache:${cacheResult['imageId']}', 
      );

      final WriteBatch batch = _firestore.batch();

      final DocumentReference messageRef = _firestore.collection(messagesCollection).doc(messageId);
      batch.set(messageRef, {
        ...message.toFirestore(),
        'imageMetadata': {
          'originalName': path.basename(imageFile.path),
          'size': cacheResult['size'],
          'contentType': cacheResult['contentType'],
        }
      });

      final DocumentReference chatRoomRef = _firestore.collection(chatRoomsCollection).doc(chatRoomId);
      batch.update(chatRoomRef, {
        'lastMessage': message.toFirestore(),
        'updatedAt': Timestamp.fromDate(now),
      });

      await batch.commit();
      log('Image message sent - 2 writes used (message + chat room update)');
      log('Image cached locally with ID: ${cacheResult['imageId']}');

      return SendMessageResponse(message: message, success: true);
    } catch (e, stack) {
      log('Error sending image message: $e');
      log('Stack trace: $stack');
      return SendMessageResponse(
        message: ChatMessage(
          id: '',
          chatRoomId: chatRoomId,
          senderId: senderId,
          senderName: senderName,
          content: 'Failed to send image',
          type: MessageType.image,
          timestamp: DateTime.now(),
        ),
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _cacheImageLocally(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      String base64Image;
      String contentType = _getContentType(imageFile.path);
      int finalSize = imageBytes.length;

      if (imageBytes.length > 1024 * 1024) { 
        img.Image? image = img.decodeImage(imageBytes);
        if (image == null) {
          return {
            'success': false,
            'error': 'Invalid image format',
          };
        }

        img.Image resized = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 800 : null,
        );

        final Uint8List compressedBytes = img.encodeJpg(resized, quality: 70);
        base64Image = base64Encode(compressedBytes);
        contentType = 'image/jpeg';
        finalSize = compressedBytes.length;
        
        log('Image compressed from ${imageBytes.length} to $finalSize bytes');
      } else {
        base64Image = base64Encode(imageBytes);
      }

      final String imageId = _uuid.v4();
      final DateTime now = DateTime.now();

      _imageCache[imageId] = base64Image;
      _imageCacheTimestamps[imageId] = now;

      _cleanExpiredCache();

      return {
        'success': true,
        'imageId': imageId,
        'size': finalSize,
        'contentType': contentType,
      };
    } catch (e) {
      log('Error caching image: $e');
      return {
        'success': false,
        'error': 'Failed to process image: $e',
      };
    }
  }

  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _imageCacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _imageCache.remove(key);
      _imageCacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      log('Cleaned ${expiredKeys.length} expired images from cache');
    }
  }

  static String? getCachedImage(String imageId) {
    _cleanExpiredCacheStatic();
    return _imageCache[imageId];
  }

  static void _cleanExpiredCacheStatic() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _imageCacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _imageCache.remove(key);
      _imageCacheTimestamps.remove(key);
    }
  }

  static void clearImageCache() {
    final count = _imageCache.length;
    _imageCache.clear();
    _imageCacheTimestamps.clear();
    log('Cleared $count images from cache');
  }

  static Map<String, dynamic> getCacheStats() {
    _cleanExpiredCacheStatic();
    final totalImages = _imageCache.length;
    int totalSize = 0;
    
    for (final base64 in _imageCache.values) {
      totalSize += (base64.length * 0.75).round(); 
    }

    return {
      'totalImages': totalImages,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  @override
  Future<UploadImageResponse> uploadImage(File imageFile) async {
    final cacheResult = await _cacheImageLocally(imageFile);
    if (cacheResult['success']) {
      return UploadImageResponse(
        imageUrl: 'cache:${cacheResult['imageId']}',
        success: true,
      );
    } else {
      return UploadImageResponse(
        imageUrl: '',
        success: false,
        error: cacheResult['error'],
      );
    }
  }

  String _getContentType(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .limit(10)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final WriteBatch batch = _firestore.batch();
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
        log('Marked ${querySnapshot.docs.length} messages as read');
      }
    } catch (e, stack) {
      log('Error marking messages as read: $e');
      log('Stack trace: $stack');
    }
  }

  @override
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      final WriteBatch batch = _firestore.batch();

      final QuerySnapshot messagesSnapshot = await _firestore
          .collection(messagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .limit(100)
          .get();

      for (QueryDocumentSnapshot doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final QuerySnapshot imagesSnapshot = await _firestore
          .collection(imagesCollection)
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      for (QueryDocumentSnapshot doc in imagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final DocumentReference chatRoomRef = _firestore.collection(chatRoomsCollection).doc(chatRoomId);
      batch.delete(chatRoomRef);

      await batch.commit();
      log('Chat room deleted - ${messagesSnapshot.docs.length + imagesSnapshot.docs.length + 1} deletes used');
    } catch (e, stack) {
      log('Error deleting chat room: $e');
      log('Stack trace: $stack');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String messageId, String chatRoomId) async {
    try {
      await _firestore.collection(messagesCollection).doc(messageId).delete();
      log('Message deleted - 1 delete used');
    } catch (e, stack) {
      log('Error deleting message: $e');
      log('Stack trace: $stack');
      rethrow;
    }
  }
}