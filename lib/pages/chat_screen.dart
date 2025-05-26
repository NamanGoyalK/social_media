part of '../components/user_list_tile.dart';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _messageStream;
  bool _isLoading = true;
  bool _canSend = false;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateSendButtonState);
    _loadMessages();
    _subscribeToMessages();
  }

  void _updateSendButtonState() {
    final canSend = _messageController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  void _loadMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$currentUserId,recipient_id.eq.${widget.recipientId}),and(sender_id.eq.${widget.recipientId},recipient_id.eq.$currentUserId)',
          )
          .order('created_at', ascending: true);

      setState(() {
        _messages.clear();
        _messages.addAll(response.map((msg) => Message.fromJson(msg)).toList());
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load messages: $e')));
      }
    }
  }

  void _subscribeToMessages() {
    _messageStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at');

    _messageStream.listen((data) {
      final filteredMessages =
          data.where((message) {
            final senderId = message['sender_id'];
            final recipientId = message['recipient_id'];

            return (senderId == currentUserId &&
                    recipientId == widget.recipientId) ||
                (senderId == widget.recipientId &&
                    recipientId == currentUserId);
          }).toList();

      _updateMessagesFromStream(filteredMessages);
    });
  }

  void _updateMessagesFromStream(List<Map<String, dynamic>> data) {
    if (mounted) {
      setState(() {
        final newMessages = data.map((msg) => Message.fromJson(msg)).toList();

        final allMessages = [..._messages, ...newMessages];
        final uniqueMessages = <String, Message>{};

        for (final message in allMessages) {
          uniqueMessages[message.id] = message;
        }

        _messages.clear();
        _messages.addAll(
          uniqueMessages.values.toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        );
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final messageData = {
        'sender_id': currentUserId,
        'recipient_id': widget.recipientId,
        'content': messageText,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase
              .from('messages')
              .insert(messageData)
              .select()
              .single();

      setState(() {
        _messages.add(Message.fromJson(response));
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      _messageController.text = messageText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 50.0, left: 25),
            child: Row(
              children: [
                MyBackButton(),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "D I R E C T  C H A T",
                    style: TextStyle(fontSize: 25),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with ${widget.recipientName}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return MessageBubble(
                          message: message,
                          isMe: message.senderId == currentUserId,
                        );
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed:
                      _messageController.text.trim().isEmpty
                          ? null
                          : _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color:
                        _messageController.text.trim().isEmpty
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        _messageController.text.trim().isEmpty
                            ? null
                            : Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(25),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
