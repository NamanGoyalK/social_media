import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final List<Map<String, dynamic>> comments;
  final int commentsCount;
  final VoidCallback onCommentsUpdated;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.comments,
    required this.commentsCount,
    required this.onCommentsUpdated,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  bool isLoading = false;
  bool isReplyLoading = false;
  String? replyingToCommentId;
  String? replyingToUsername;

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _showMessage('Please sign in to comment');
        return;
      }

      setState(() {
        isLoading = true;
      });

      await supabase.from('post_comments').insert({
        'post_id': widget.postId,
        'user_id': userId,
        'content': _commentController.text.trim(),
        'parent_comment_id': null, // Top-level comment
      });

      _commentController.clear();
      widget.onCommentsUpdated();
      _showMessage('Comment added successfully!');
    } catch (e) {
      if (kDebugMode) {
        print('Error adding comment: $e');
      }
      _showMessage('Error adding comment: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addReply() async {
    if (_replyController.text.trim().isEmpty || replyingToCommentId == null) {
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _showMessage('Please sign in to reply');
        return;
      }

      setState(() {
        isReplyLoading = true;
      });

      await supabase.from('post_comments').insert({
        'post_id': widget.postId,
        'user_id': userId,
        'content': _replyController.text.trim(),
        'parent_comment_id': replyingToCommentId,
      });

      _replyController.clear();
      _cancelReply();
      widget.onCommentsUpdated();
      _showMessage('Reply added successfully!');
    } catch (e) {
      if (kDebugMode) {
        print('Error adding reply: $e');
      }
      _showMessage('Error adding reply: $e');
    } finally {
      setState(() {
        isReplyLoading = false;
      });
    }
  }

  void _startReply(String commentId, String username) {
    setState(() {
      replyingToCommentId = commentId;
      replyingToUsername = username;
    });
    // Focus on reply text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelReply() {
    setState(() {
      replyingToCommentId = null;
      replyingToUsername = null;
    });
    _replyController.clear();
  }

  List<Map<String, dynamic>> _getTopLevelComments() {
    return widget.comments
        .where((comment) => comment['parent_comment_id'] == null)
        .toList();
  }

  List<Map<String, dynamic>> _getRepliesForComment(String commentId) {
    return widget.comments
        .where((comment) => comment['parent_comment_id'] == commentId)
        .toList()
      ..sort(
        (a, b) => DateTime.parse(
          a['created_at'],
        ).compareTo(DateTime.parse(b['created_at'])),
      );
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildCommentTile(
    Map<String, dynamic> comment, {
    bool isReply = false,
  }) {
    final user = comment['Users'];
    final replies =
        isReply
            ? <Map<String, dynamic>>[]
            : _getRepliesForComment(comment['id']);

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: isReply ? 32.0 : 0.0),
          child: ListTile(
            leading: CircleAvatar(
              radius: isReply ? 16 : 20,
              backgroundImage:
                  user?['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
              child:
                  user?['avatar_url'] == null
                      ? Text(
                        user?['username']?[0] ?? 'U',
                        style: TextStyle(fontSize: isReply ? 12 : 16),
                      )
                      : null,
            ),
            title: Text(
              user?['username'] ?? 'Anonymous',
              style: TextStyle(fontSize: isReply ? 14 : 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment['content'],
                  style: TextStyle(fontSize: isReply ? 13 : 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDateTime(comment['created_at']),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: isReply ? 11 : 12,
                      ),
                    ),
                    if (!isReply) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap:
                            () => _startReply(
                              comment['id'],
                              user?['username'] ?? 'Anonymous',
                            ),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // Show replies
        if (!isReply && replies.isNotEmpty)
          ...replies.map((reply) => _buildCommentTile(reply, isReply: true)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder:
          (context, scrollController) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Comments (${widget.commentsCount})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _getTopLevelComments().length,
                      itemBuilder: (context, index) {
                        final comment = _getTopLevelComments()[index];
                        return _buildCommentTile(comment);
                      },
                    ),
                  ),
                  // Reply indicator
                  if (replyingToCommentId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Replying to $replyingToUsername',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _cancelReply,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 16, 16, 28),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.inversePrimary.withAlpha(150),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller:
                                replyingToCommentId != null
                                    ? _replyController
                                    : _commentController,
                            decoration: InputDecoration(
                              hintText:
                                  replyingToCommentId != null
                                      ? 'Add a reply...'
                                      : 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        (isLoading || isReplyLoading)
                            ? const CircularProgressIndicator()
                            : IconButton(
                              onPressed:
                                  replyingToCommentId != null
                                      ? _addReply
                                      : _addComment,
                              icon: const Icon(Icons.send),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
