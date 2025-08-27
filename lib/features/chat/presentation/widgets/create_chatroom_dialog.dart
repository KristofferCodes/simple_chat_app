import 'package:flutter/material.dart';
import '../bloc/chat_bloc.dart';

class CreateChatRoomDialog extends StatefulWidget {
  final ChatBloc chatBloc;  

  const CreateChatRoomDialog({
    Key? key,
    required this.chatBloc,
  }) : super(key: key);

  @override
  State<CreateChatRoomDialog> createState() => _CreateChatRoomDialogState();
}

class _CreateChatRoomDialogState extends State<CreateChatRoomDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Chat Room'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Room Name',
              hintText: 'Enter room name',
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _participantsController,
            decoration: InputDecoration(
              labelText: 'Participants',
              hintText: 'Enter participant names (comma separated)',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final participantsText = _participantsController.text.trim();
            
            if (name.isNotEmpty) {
              final participants = participantsText.isNotEmpty 
                  ? participantsText.split(',').map((e) => e.trim()).toList()
                  : <String>[];
              
              widget.chatBloc.add(CreateChatRoomEvent(
                name: name,
                participantNames: participants,
              ));
              
              Navigator.pop(context);
            }
          },
          child: Text('Create'),
        ),
      ],
    );
  }
}