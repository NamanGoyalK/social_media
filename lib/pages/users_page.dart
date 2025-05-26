import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/user_list_tile.dart';
import '../components/back_button.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<List<dynamic>>(
        future: Supabase.instance.client
            .from('Users')
            .select()
            .then((response) => response as List<dynamic>),
        builder: (context, snapshot) {
          // any errors
          if (snapshot.hasError) {
            String errorMessage = "Something went wrong";
            if (snapshot.error.toString().contains("BAD_DECRYPT") ||
                snapshot.error.toString().contains(
                  "DECRYPTION_FAILED_OR_BAD_RECORD_MAC",
                )) {
              errorMessage =
                  "Decryption error or invalid API response. Please try again later.";
            }
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // show loading circle
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Data"));
          }

          // get all users
          final users = snapshot.data!;

          return Column(
            children: [
              // back button
              const Padding(
                padding: EdgeInsets.only(top: 50.0, left: 25),
                child: Row(
                  children: [
                    MyBackButton(),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("U S E R S", style: TextStyle(fontSize: 25)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // list of users in the app
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.all(0),
                  itemBuilder: (context, index) {
                    // get individual user
                    final user = users[index];

                    // get data from each user
                    String username = user["username"];
                    String email = user["email"];
                    String userId = user["id"];

                    return UserListTile(
                      title: username,
                      subTitle: email,
                      userId: userId,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
