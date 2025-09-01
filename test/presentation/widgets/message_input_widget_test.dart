import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_chat_app/features/chat/presentation/widgets/message_input_widget.dart';

void main() {
  group('MessageInputWidget', () {
    late String capturedMessage;
    late bool imageButtonPressed;

    setUp(() {
      capturedMessage = '';
      imageButtonPressed = false;
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: MessageInputWidget(
            onTextMessageSent: (message) {
              capturedMessage = message;
            },
            onImageMessageSent: () {
              imageButtonPressed = true;
            },
            isLoading: false,
          ),
        ),
      );
    }

    testWidgets('should display text field and image button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('should show send button when text is entered', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act
      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should hide send button when text field is empty', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      
      // Clear the text
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.send), findsNothing);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('should call onTextMessageSent when send button is pressed', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());
      const testMessage = 'Test message';

      // Act
      await tester.enterText(find.byType(TextField), testMessage);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Assert
      expect(capturedMessage, testMessage);
      expect(find.text(testMessage), findsNothing); // Text field should be cleared
    });

    testWidgets('should call onTextMessageSent when submitted via keyboard', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());
      const testMessage = 'Keyboard test';

      // Act
      await tester.enterText(find.byType(TextField), testMessage);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // Assert
      expect(capturedMessage, testMessage);
    });

    testWidgets('should call onImageMessageSent when camera button is pressed', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act
      await tester.tap(find.byIcon(Icons.photo_camera));
      await tester.pump();

      // Assert
      expect(imageButtonPressed, true);
    });

    testWidgets('should call onImageMessageSent when attach button is pressed', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act - tap attach file icon (visible when no text)
      await tester.tap(find.byIcon(Icons.attach_file));
      await tester.pump();

      // Assert
      expect(imageButtonPressed, true);
    });

    testWidgets('should not send empty or whitespace-only messages', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act - try to send empty message
      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // Assert
      expect(capturedMessage, '');

      // Act - try to send whitespace-only message
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      
      // Send button should not be visible for whitespace-only text
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('should trim whitespace from messages before sending', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());
      const messageWithWhitespace = '  Hello World  ';
      const expectedTrimmedMessage = 'Hello World';

      // Act
      await tester.enterText(find.byType(TextField), messageWithWhitespace);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Assert
      expect(capturedMessage, expectedTrimmedMessage);
    });

    testWidgets('should handle loading state correctly', (tester) async {
      // Arrange
      Widget loadingWidget = MaterialApp(
        home: Scaffold(
          body: MessageInputWidget(
            onTextMessageSent: (message) {},
            onImageMessageSent: () {},
            isLoading: true,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(loadingWidget);

      // Assert - widget should still be interactive during loading
      // (Your current implementation doesn't disable during loading, 
      // but you might want to test this behavior if you implement it)
      expect(find.byType(TextField), findsOneWidget);
    });

    group('Text field styling and behavior', () {
      testWidgets('should have correct border styling', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        final decoration = textField.decoration!;
        
        expect(decoration.hintText, 'Type a message...');
        expect(decoration.border, isA<OutlineInputBorder>());
      });

      testWidgets('should support multi-line text input', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());

        // Act
        await tester.enterText(find.byType(TextField), 'Line 1\nLine 2\nLine 3');
        await tester.pump();

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.maxLines, isNull); // Should allow multiple lines
      });
    });

    group('Edge cases', () {
      testWidgets('should handle very long messages', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());
        final longMessage = 'A' * 1000; // Very long message

        // Act
        await tester.enterText(find.byType(TextField), longMessage);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Assert
        expect(capturedMessage, longMessage);
      });

      testWidgets('should handle special characters', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());
        const specialMessage = 'Hello! 🎉 @user #hashtag & more';

        // Act
        await tester.enterText(find.byType(TextField), specialMessage);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Assert
        expect(capturedMessage, specialMessage);
      });
    });
  });
}