import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../components/drawer.dart';
import '../components/post_list_tile.dart';
import '../components/post_button.dart';
import '../components/textfield.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text controller
  final TextEditingController newPostController = TextEditingController();

  // image picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;

  // pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  // remove selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // upload image to Supabase Storage
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('post-images')
          .uploadBinary(fileName, bytes);

      final imageUrl = Supabase.instance.client.storage
          .from('post-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      return null;
    }
  }

  // post message with optional image
  void postMessage() async {
    if (newPostController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a message or image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      // Insert post into database
      await Supabase.instance.client.from('posts').insert({
        'PostMessage':
            newPostController.text.isEmpty ? null : newPostController.text,
        'UserEmail': Supabase.instance.client.auth.currentUser?.email,
        'ImageUrl': imageUrl,
      });

      // Clear form
      newPostController.clear();
      setState(() {
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("T H E W A L L"),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          // POST CREATION SECTION
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                // Image preview if selected
                if (_selectedImage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withAlpha(
                          77,
                        ), // 77 is approximately 30% opacity
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
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
                            child: Image.file(
                              _selectedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(153),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Text input and buttons row
                Row(
                  children: [
                    // Camera button
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withAlpha(25), // 25 is approximately 10% opacity
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(
                              77,
                            ), // 77 is approximately 30% opacity
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // textfield
                    Expanded(
                      child: MyTextfield(
                        hintText: "Say something",
                        obscureText: false,
                        controller: newPostController,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // post button
                    _isUploading
                        ? Container(
                          padding: const EdgeInsets.all(12),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : PostButton(onTap: postMessage),
                  ],
                ),
              ],
            ),
          ),

          // POSTS
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('posts')
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
                    String message = post['PostMessage'] ?? '';
                    String userEmail = post['UserEmail'] ?? 'Unknown';
                    String postedAt = post['created_at'] ?? 'Unknown';
                    int postId = post['id'] ?? 0;
                    String? imageUrl = post['ImageUrl'];

                    // return as a list tile
                    return PostListTile(
                      title: message,
                      subTitle: userEmail,
                      postedAt: postedAt,
                      postId: postId.toString(),
                      authorId: userEmail,
                      imageUrl: imageUrl,
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
