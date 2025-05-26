import 'package:flutter/material.dart';
import 'package:social_media/components/back_button.dart';
import 'package:social_media/components/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part '../pages/chat_screen.dart';

class UserListTile extends StatelessWidget {
  final String title;
  final String subTitle;
  final String userId;
  final VoidCallback? onChatPressed;

  const UserListTile({
    super.key,
    required this.title,
    required this.subTitle,
    required this.userId,
    this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          title: Text(title),
          subtitle: Text(
            subTitle,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.inversePrimary.withAlpha(150),
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: onChatPressed ?? () => _handleChatPress(context),
            tooltip: 'Start Chat',
          ),
        ),
      ),
    );
  }

  void _handleChatPress(BuildContext context) {
    _navigateToChat(context);
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(recipientId: userId, recipientName: title),
      ),
    );
  }
}
