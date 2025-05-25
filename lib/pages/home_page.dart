import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/drawer.dart';
import '../components/post_list_tile.dart';
import '../components/post_button.dart';
import '../components/textfield.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // text controller
  final TextEditingController newPostController = TextEditingController();

  // post message
  void postMessage() async {
    if (newPostController.text.isNotEmpty) {
      await Supabase.instance.client.from('Posts').insert({
        'PostMessage': newPostController.text,
        'UserEmail': Supabase.instance.client.auth.currentUser?.email,
      });
    }

    newPostController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("T H E  W A L L"),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          // TEXTFIELD BOX FOR USER TO TYPE
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              children: [
                // textfield
                Expanded(
                  child: MyTextfield(
                    hintText: "Say something",
                    obscureText: false,
                    controller: newPostController,
                  ),
                ),

                // post button
                PostButton(onTap: postMessage),
              ],
            ),
          ),

          // POSTS
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('Posts')
                .stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              // show loading circle
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // handle errors
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              // get all posts
              final posts = snapshot.data;

              // no data?
              if (posts == null || posts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25.0),
                    child: Text("No Posts.. Post something!"),
                  ),
                );
              }

              // return as a list
              return Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    // get each individual post
                    final post = posts[index];

                    // get data from each post
                    String message = post['PostMessage'] ?? 'No message';
                    String userEmail = post['UserEmail'] ?? 'Unknown';
                    String postedAt = post['created_at'] ?? 'Unknown';
                    int postId = post['id'] ?? '';

                    // return as a list tile
                    return PostListTile(
                      title: message,
                      subTitle: userEmail,
                      postedAt: postedAt,
                      postId: postId.toString(),
                      authorId: userEmail,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
