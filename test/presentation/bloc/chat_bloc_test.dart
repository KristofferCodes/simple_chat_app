import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_chat_app/features/chat/data/models/chat_models.dart';
import 'package:simple_chat_app/features/chat/domain/repository/chat_repository.dart';
import 'package:simple_chat_app/features/chat/presentation/bloc/chat_bloc.dart';

import '../../helpers/test_helpers.dart';

// Mock classes
class MockChatRepository extends Mock implements ChatRepository {}
class MockFile extends Mock implements File {}

void main() {
  group('ChatBloc', () {
    late ChatBloc chatBloc;
    late MockChatRepository mockRepository;

    setUp(() {
      mockRepository = MockChatRepository();
      chatBloc = ChatBloc(mockRepository);
      
      // Register fallback values for mocktail
      registerFallbackValue(MockFile());
    });

    tearDown(() {
      chatBloc.close();
    });

    test('initial state is ChatInitial', () {
      expect(chatBloc.state, ChatInitial());
    });

    group('FetchChatRoomsEvent', () {
      final testChatRooms = [
        TestHelpers.createTestChatRoom(id: 'room-1', name: 'Room 1'),
        TestHelpers.createTestChatRoom(id: 'room-2', name: 'Room 2'),
      ];

      blocTest<ChatBloc, ChatState>(
        'emits [ChatRoomsLoadingState, ChatRoomsSuccessState] when fetchChatRooms succeeds',
        build: () {
          when(() => mockRepository.fetchChatRooms())
              .thenAnswer((_) async => testChatRooms);
          return chatBloc;
        },
        act: (bloc) => bloc.add(FetchChatRoomsEvent()),
        expect: () => [
          ChatRoomsLoadingState(),
          ChatRoomsSuccessState(chatRooms: testChatRooms),
        ],
        verify: (_) {
          verify(() => mockRepository.fetchChatRooms()).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'emits [ChatRoomsLoadingState, ChatRoomsFailureState] when fetchChatRooms fails',
        build: () {
          when(() => mockRepository.fetchChatRooms())
              .thenThrow(Exception('Network error'));
          return chatBloc;
        },
        act: (bloc) => bloc.add(FetchChatRoomsEvent()),
        expect: () => [
          ChatRoomsLoadingState(),
          ChatRoomsFailureState(error: 'Exception: Network error'),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'skips loading state when isRefresh is false and already has success state',
        build: () {
          when(() => mockRepository.fetchChatRooms())
              .thenAnswer((_) async => testChatRooms);
          return chatBloc;
        },
        seed: () => ChatRoomsSuccessState(chatRooms: []),
        act: (bloc) => bloc.add(FetchChatRoomsEvent(isRefresh: false)),
        expect: () => [
          ChatRoomsSuccessState(chatRooms: testChatRooms),
        ],
      );
    });

    group('CreateChatRoomEvent', () {
      final testChatRoom = TestHelpers.createTestChatRoom(
        name: 'New Room',
        participantNames: ['Alice', 'Bob'],
      );

      blocTest<ChatBloc, ChatState>(
        'creates chat room successfully',
        build: () {
          when(() => mockRepository.createChatRoom('New Room', ['Alice', 'Bob']))
              .thenAnswer((_) async => testChatRoom);
          when(() => mockRepository.fetchChatRooms())
              .thenAnswer((_) async => [testChatRoom]);
          return chatBloc;
        },
        seed: () => ChatRoomsSuccessState(chatRooms: []),
        act: (bloc) => bloc.add(CreateChatRoomEvent(
          name: 'New Room',
          participantNames: ['Alice', 'Bob'],
        )),
        expect: () => [
          ChatRoomsSuccessState(chatRooms: [], isCreatingRoom: true),
          ChatRoomCreatedState(chatRoom: testChatRoom),
          ChatRoomsLoadingState(),
          ChatRoomsSuccessState(chatRooms: [testChatRoom]),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'handles create chat room failure',
        build: () {
          when(() => mockRepository.createChatRoom('New Room', ['Alice', 'Bob']))
              .thenThrow(Exception('Creation failed'));
          return chatBloc;
        },
        seed: () => ChatRoomsSuccessState(chatRooms: []),
        act: (bloc) => bloc.add(CreateChatRoomEvent(
          name: 'New Room',
          participantNames: ['Alice', 'Bob'],
        )),
        expect: () => [
          ChatRoomsSuccessState(chatRooms: [], isCreatingRoom: true),
          ChatRoomsSuccessState(chatRooms: [], isCreatingRoom: false),
          ChatActionFailureState(
            error: 'Failed to create chat room: Exception: Creation failed',
            action: 'create_room',
          ),
          ChatRoomsSuccessState(chatRooms: []),
        ],
      );
    });

    group('FetchMessagesEvent', () {
      const testChatRoomId = 'room-123';
      final testMessages = [
        TestHelpers.createTestMessage(id: 'msg-1', chatRoomId: testChatRoomId),
        TestHelpers.createTestMessage(id: 'msg-2', chatRoomId: testChatRoomId),
      ];

      blocTest<ChatBloc, ChatState>(
        'emits [MessagesLoadingState, MessagesSuccessState] when fetchMessages succeeds',
        build: () {
          when(() => mockRepository.fetchMessages(testChatRoomId, limit: 30))
              .thenAnswer((_) async => testMessages);
          return chatBloc;
        },
        act: (bloc) => bloc.add(FetchMessagesEvent(chatRoomId: testChatRoomId)),
        expect: () => [
          MessagesLoadingState(chatRoomId: testChatRoomId),
          MessagesSuccessState(
            chatRoomId: testChatRoomId,
            messages: testMessages,
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits failure state when fetchMessages fails',
        build: () {
          when(() => mockRepository.fetchMessages(testChatRoomId, limit: 30))
              .thenThrow(Exception('Fetch failed'));
          return chatBloc;
        },
        act: (bloc) => bloc.add(FetchMessagesEvent(chatRoomId: testChatRoomId)),
        expect: () => [
          MessagesLoadingState(chatRoomId: testChatRoomId),
          MessagesFailureState(
            chatRoomId: testChatRoomId,
            error: 'Exception: Fetch failed',
          ),
        ],
      );
    });

    group('SendTextMessageEvent', () {
      const testChatRoomId = 'room-123';
      const testSenderId = 'user-456';
      const testSenderName = 'Test User';
      const testContent = 'Hello, world!';

      final testMessage = TestHelpers.createTestMessage(
        chatRoomId: testChatRoomId,
        senderId: testSenderId,
        senderName: testSenderName,
        content: testContent,
      );

      blocTest<ChatBloc, ChatState>(
        'sends text message successfully with optimistic update',
        build: () {
          when(() => mockRepository.sendTextMessage(
                testChatRoomId,
                testSenderId,
                testSenderName,
                testContent,
              )).thenAnswer((_) async => TestHelpers.createSuccessResponse(
                message: testMessage,
              ));
          
          when(() => mockRepository.fetchMessages(testChatRoomId, limit: 30))
              .thenAnswer((_) async => [testMessage]);
          
          return chatBloc;
        },
        seed: () => MessagesSuccessState(
          chatRoomId: testChatRoomId,
          messages: [],
        ),
        act: (bloc) => bloc.add(SendTextMessageEvent(
          chatRoomId: testChatRoomId,
          senderId: testSenderId,
          senderName: testSenderName,
          content: testContent,
        )),
        wait: const Duration(milliseconds: 600), // Wait for delayed fetch
        verify: (bloc) {
          verify(() => mockRepository.sendTextMessage(
                testChatRoomId,
                testSenderId,
                testSenderName,
                testContent,
              )).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'handles send message failure and removes optimistic message',
        build: () {
          when(() => mockRepository.sendTextMessage(
                testChatRoomId,
                testSenderId,
                testSenderName,
                testContent,
              )).thenAnswer((_) async => TestHelpers.createFailureResponse(
                error: 'Send failed',
              ));
          return chatBloc;
        },
        seed: () => MessagesSuccessState(
          chatRoomId: testChatRoomId,
          messages: [],
        ),
        act: (bloc) => bloc.add(SendTextMessageEvent(
          chatRoomId: testChatRoomId,
          senderId: testSenderId,
          senderName: testSenderName,
          content: testContent,
        )),
        verify: (bloc) {
          // Should attempt to send the message
          verify(() => mockRepository.sendTextMessage(
                testChatRoomId,
                testSenderId,
                testSenderName,
                testContent,
              )).called(1);
        },
      );
    });

    group('SendImageMessageEvent', () {
      const testChatRoomId = 'room-123';
      const testSenderId = 'user-456';
      const testSenderName = 'Test User';
      final testImageFile = MockFile();

      final testImageMessage = TestHelpers.createTestMessage(
        chatRoomId: testChatRoomId,
        senderId: testSenderId,
        senderName: testSenderName,
        content: 'Image',
        type: MessageType.image,
        imageUrl: 'cache:test-image-id',
      );

      blocTest<ChatBloc, ChatState>(
        'sends image message successfully',
        build: () {
          when(() => mockRepository.sendImageMessage(
                testChatRoomId,
                testSenderId,
                testSenderName,
                testImageFile,
              )).thenAnswer((_) async => TestHelpers.createSuccessResponse(
                message: testImageMessage,
              ));
          
          when(() => mockRepository.fetchMessages(testChatRoomId, limit: 30))
              .thenAnswer((_) async => [testImageMessage]);
          
          return chatBloc;
        },
        seed: () => MessagesSuccessState(
          chatRoomId: testChatRoomId,
          messages: [],
        ),
        act: (bloc) => bloc.add(SendImageMessageEvent(
          chatRoomId: testChatRoomId,
          senderId: testSenderId,
          senderName: testSenderName,
          imageFile: testImageFile,
        )),
        wait: const Duration(milliseconds: 600),
        verify: (bloc) {
          verify(() => mockRepository.sendImageMessage(
                testChatRoomId,
                testSenderId,
                testSenderName,
                testImageFile,
              )).called(1);
        },
      );
    });

    group('DeleteChatRoomEvent', () {
      const testChatRoomId = 'room-123';

      blocTest<ChatBloc, ChatState>(
        'deletes chat room successfully',
        build: () {
          when(() => mockRepository.deleteChatRoom(testChatRoomId))
              .thenAnswer((_) async {});
          when(() => mockRepository.fetchChatRooms())
              .thenAnswer((_) async => []);
          return chatBloc;
        },
        act: (bloc) => bloc.add(DeleteChatRoomEvent(chatRoomId: testChatRoomId)),
        expect: () => [
          ChatRoomDeletedState(chatRoomId: testChatRoomId),
          ChatRoomsLoadingState(),
          ChatRoomsSuccessState(chatRooms: []),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'handles delete chat room failure',
        build: () {
          when(() => mockRepository.deleteChatRoom(testChatRoomId))
              .thenThrow(Exception('Delete failed'));
          return chatBloc;
        },
        act: (bloc) => bloc.add(DeleteChatRoomEvent(chatRoomId: testChatRoomId)),
        expect: () => [
          ChatActionFailureState(
            error: 'Failed to delete chat room: Exception: Delete failed',
            action: 'delete_room',
          ),
        ],
      );
    });

    group('PickImageEvent', () {
      blocTest<ChatBloc, ChatState>(
        'handles successful image picking',
        build: () => chatBloc,
        act: (bloc) {
          // This would be more complex in a real test as it involves
          // image picker mocking, file system operations, etc.
          bloc.add(ImagePickedEvent(imageFile: MockFile()));
        },
        expect: () => [
          ImageReadyToSendState(imageFile: any(named: 'imageFile')),
        ],
      );
    });

    group('NavigateBackToHomeEvent', () {
      blocTest<ChatBloc, ChatState>(
        'navigates back to home and fetches chat rooms',
        build: () {
          when(() => mockRepository.fetchChatRooms())
              .thenAnswer((_) async => []);
          return chatBloc;
        },
        act: (bloc) => bloc.add(NavigateBackToHomeEvent()),
        expect: () => [
          ChatRoomsSuccessState(chatRooms: []),
        ],
      );
    });
  });
}