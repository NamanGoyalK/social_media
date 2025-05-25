import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostListTile extends StatefulWidget {
  final String postId;
  final String title;
  final String subTitle;
  final String postedAt;
  final String authorId;

  const PostListTile({
    super.key,
    required this.postId,
    required this.title,
    required this.subTitle,
    required this.postedAt,
    required this.authorId,
  });

  @override
  State<PostListTile> createState() => _PostListTileState();
}

class _PostListTileState extends State<PostListTile> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();

  bool isLiked = false;
  int likesCount = 0;
  int commentsCount = 0;
  bool showComments = false;
  List<Map<String, dynamic>> comments = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostData() async {
    await Future.wait([_checkIfLiked(), _loadLikesCount(), _loadComments()]);
  }

  Future<void> _checkIfLiked() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response =
          await supabase
              .from('post_likes')
              .select()
              .eq('post_id', widget.postId)
              .eq('user_id', userId)
              .maybeSingle();

      if (mounted) {
        setState(() {
          isLiked = response != null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking like status: $e');
      }
    }
  }

  Future<void> _loadLikesCount() async {
    try {
      final response = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', widget.postId);

      if (mounted) {
        setState(() {
          likesCount = response.length;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading likes count: $e');
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final response = await supabase
          .from('post_comments')
          .select('''
          id,
          content,
          created_at,
          user_id,
          Users:user_id (
            username,
            email
          )
        ''')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          comments = List<Map<String, dynamic>>.from(response);
          commentsCount = comments.length;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading comments: $e');
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _showMessage('Please sign in to like posts');
        return;
      }

      if (isLiked) {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', widget.postId)
            .eq('user_id', userId);
      } else {
        await supabase.from('post_likes').insert({
          'post_id': widget.postId,
          'user_id': userId,
        });
      }

      await _loadLikesCount();
      await _checkIfLiked();
    } catch (e) {
      _showMessage('Error updating like: $e');
    }
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

      // Insert the comment
      await supabase.from('post_comments').insert({
        'post_id': widget.postId,
        'user_id': userId,
        'content': _commentController.text.trim(),
      });

      _commentController.clear();

      // Reload comments to refresh the UI
      await _loadComments();

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

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
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
                          'Comments ($commentsCount)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final user = comment['Users']; // Corrected key
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    user?['avatar_url'] != null
                                        ? NetworkImage(user['avatar_url'])
                                        : null,
                                child:
                                    user?['avatar_url'] == null
                                        ? Text(user?['username']?[0] ?? 'U')
                                        : null,
                              ),
                              title: Text(
                                user?['username'] ?? 'Anonymous',
                              ), // Corrected key
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment['content']),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(comment['created_at']),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                maxLines: null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            isLoading
                                ? const CircularProgressIndicator()
                                : IconButton(
                                  onPressed: _addComment,
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

  String _formatDateTime(String dateTimeString) {
    final dateTime =
        DateTime.parse(dateTimeString).toLocal(); // Convert to local time
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(widget.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subTitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "${DateTime.parse(widget.postedAt).hour.toString().padLeft(2, '0')}:${DateTime.parse(widget.postedAt).minute.toString().padLeft(2, '0')} | ${DateTime.parse(widget.postedAt).day.toString().padLeft(2, '0')}/${DateTime.parse(widget.postedAt).month.toString().padLeft(2, '0')}/${DateTime.parse(widget.postedAt).year.toString().substring(2)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like button
                  InkWell(
                    onTap: _toggleLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color:
                                isLiked
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.inversePrimary.withAlpha(150)
                                    : Theme.of(
                                      context,
                                    ).colorScheme.inversePrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            likesCount.toString(),
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Comment button
                  InkWell(
                    onTap: _showCommentsBottomSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            commentsCount.toString(),
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
