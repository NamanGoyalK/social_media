import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comments_bottom_sheet.dart';

class PostListTile extends StatefulWidget {
  final String postId;
  final String title;
  final String subTitle;
  final String postedAt;
  final String authorId;
  final String? imageUrl;

  const PostListTile({
    super.key,
    required this.postId,
    required this.title,
    required this.subTitle,
    required this.postedAt,
    required this.authorId,
    this.imageUrl,
  });

  @override
  State<PostListTile> createState() => _PostListTileState();
}

class _PostListTileState extends State<PostListTile> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool isLiked = false;
  int likesCount = 0;
  int commentsCount = 0;
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    _loadPostData();
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
          parent_comment_id,
          users:user_id (
            username,
            email
          )
        ''')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          comments = List<Map<String, dynamic>>.from(response);
          // Count only top-level comments for the main counter
          commentsCount =
              comments.where((c) => c['parent_comment_id'] == null).length;
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
          (context) => CommentsBottomSheet(
            postId: widget.postId,
            comments: comments,
            commentsCount: commentsCount,
            onCommentsUpdated: _loadComments,
          ),
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post content section
            ListTile(
              title: widget.title.isNotEmpty ? Text(widget.title) : null,
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

            // Image section (if exists)
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: Image.network(
                      widget.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.inversePrimary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              strokeWidth: 2,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.inversePrimary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.inversePrimary.withAlpha(127),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inversePrimary.withAlpha(127),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Action buttons section
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
                                    ).colorScheme.inversePrimary.withAlpha(190)
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
