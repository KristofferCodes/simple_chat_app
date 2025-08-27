import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/chat/data/models/chat_models.dart';
import 'features/chat/data/repository/firebase_chat_repository.dart';
import 'features/chat/domain/repository/chat_repository.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/presentation/screens/chat_home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
      await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  runApp(SimpleChatApp());
}

class SimpleChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF2196F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
        ),
      ),
      home: ChatHomeScreen(),
    );
  }
}

class AppConstants {
  static const String appName = 'Simple Chat';
  static const int maxImageSizeMB = 5;
  static const List<String> supportedImageFormats = ['.jpg', '.jpeg', '.png', '.gif'];
  
  static const String defaultUserId = 'anonymous_user';
  static const String defaultUserName = 'Anonymous';
}

class ChatHelpers {
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  static String formatChatRoomTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  static String getMessagePreview(ChatMessage message) {
    if (message.type == MessageType.image) {
      return '📷 Image';
    }
    return message.content.length > 50 
        ? '${message.content.substring(0, 50)}...'
        : message.content;
  }
}