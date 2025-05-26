import 'package:flutter/material.dart';
import 'package:social_media/components/post_list_tile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/back_button.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  // current logged-in user
  final user = Supabase.instance.client.auth.currentUser;

  // future to fetch user details
  Future<Map<String, dynamic>?> getUserDetails() async {
    if (user?.email == null) {
      throw Exception("User email is null");
    }

    final response =
        await Supabase.instance.client
            .from('users')
            .select()
            .eq('email', user!.email!)
            .maybeSingle();

    if (response == null) {
      throw Exception("User not found");
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserDetails(),
        builder: (context, snapshot) {
          // loading..
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // error
          else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Text("Error: ${snapshot.error}")],
              ),
            );
          }
          // data received
          else if (snapshot.hasData) {
            // extract data
            final user = snapshot.data!;

            return Center(
              child: Column(
                children: [
                  // back button
                  const Padding(
                    padding: EdgeInsets.only(top: 50.0, left: 25),
                    child: Row(children: [MyBackButton()]),
                  ),

                  const SizedBox(height: 25),

                  // profile pic
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.all(25),
                    child: const Icon(Icons.person_rounded, size: 65),
                  ),

                  const SizedBox(height: 25),

                  // username
                  Text(
                    user["username"],
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // email
                  Text(
                    user["email"],
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "M Y  P O S T S",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Supabase.instance.client
                          .from('posts')
                          .select()
                          .eq('UserEmail', user["email"])
                          .order('created_at', ascending: false)
                          .then((response) => response),
                      builder: (context, postSnapshot) {
                        if (postSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (postSnapshot.hasError) {
                          return Center(
                            child: Text("Error: ${postSnapshot.error}"),
                          );
                        } else if (postSnapshot.hasData &&
                            postSnapshot.data!.isNotEmpty) {
                          final posts = postSnapshot.data!;
                          return ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return Dismissible(
                                key: Key(post["id"].toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inversePrimary.withAlpha(100),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  try {
                                    await Supabase.instance.client
                                        .from('post_comments')
                                        .delete()
                                        .eq('post_id', post["id"]);

                                    await Supabase.instance.client
                                        .from('post_likes')
                                        .delete()
                                        .eq('post_id', post["id"]);

                                    // Delete the post
                                    await Supabase.instance.client
                                        .from('posts')
                                        .delete()
                                        .eq('id', post["id"]);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Post deleted successfully",
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Error deleting post: $e",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: PostListTile(
                                  title: post["PostMessage"],
                                  subTitle: post["UserEmail"],
                                  postedAt: post["created_at"],
                                  postId: post["id"].toString(),
                                  authorId: post["UserEmail"],
                                ),
                              );
                            },
                          );
                        } else {
                          return const Center(child: Text("No posts found"));
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Text("No data");
          }
        },
      ),
    );
  }
}
