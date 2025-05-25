import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatabase {
  // Supabase client instance
  final SupabaseClient supabase = Supabase.instance.client;

  // post a message
  Future<void> addPost(String message) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('Posts').insert({
        'UserEmail': user.email,
        'PostMessage': message,
        'Timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // read posts from database
  Stream<List<Map<String, dynamic>>> getPostsStream() {
    return supabase
        .from('Posts')
        .stream(primaryKey: ['id'])
        .order('Timestamp', ascending: false)
        .map((data) => data.map((e) => e).toList());
  }
}
