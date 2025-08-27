import 'package:flutter/material.dart';

class MessageInputWidget extends StatefulWidget {
  final Function(String) onTextMessageSent;
  final VoidCallback onImageMessageSent;
  final bool isLoading;

  const MessageInputWidget({
    Key? key,
    required this.onTextMessageSent,
    required this.onImageMessageSent,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _textController = TextEditingController();
  bool _canSendMessage = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateSendButtonState);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }


  void _updateSendButtonState() {
    final canSend = _textController.text.trim().isNotEmpty;
    if (_canSendMessage != canSend) {
      setState(() {
        _canSendMessage = canSend;
      });
    }
  }

   @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: widget.onImageMessageSent,
              icon: Icon(
                Icons.photo_camera,
                color: Theme.of(context).primaryColor,
              ),
              tooltip: 'Send Image',
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _canSendMessage
                      ? IconButton(
                          onPressed: _sendMessage,
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _canSendMessage ? (_) => _sendMessage() : null,
              ),
            ),
            SizedBox(width: 8),
            if (!_canSendMessage) ...[
              Container(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: widget.onImageMessageSent,
                  icon: Icon(
                    Icons.attach_file,
                    color: Theme.of(context).primaryColor,
                  ),
                  tooltip: 'Attach File',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


    void _sendMessage() {
    if (_canSendMessage) {
      final message = _textController.text.trim();
      _textController.clear();
      setState(() {
        _canSendMessage = false;
      });
      widget.onTextMessageSent(message);
    }
  }
}