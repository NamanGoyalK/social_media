import 'package:flutter/material.dart';
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
            .from('Users')
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
