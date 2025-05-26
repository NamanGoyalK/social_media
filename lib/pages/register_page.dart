import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/button.dart';
import '../components/textfield.dart';
import '../helper/helper_functions.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Register method
  void registerUser() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // make sure passwords match
    if (passwordController.text != confirmPasswordController.text) {
      // pop the loading circle
      Navigator.pop(context);

      // show error message to user
      displayMessageToUser("Passwords don't match!", context);
    } else {
      // try creating the user's account
      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: emailController.text,
          password: passwordController.text,
          data: {'username': usernameController.text},
        );

        if (response.user == null) {
          throw Exception("Registration failed");
        }

        // Add user to the Users table
        await Supabase.instance.client.from('Users').insert({
          'username': usernameController.text,
          'email': emailController.text,
        });

        // pop loading circle
        if (mounted) Navigator.pop(context);

        // Navigate to login page and display success message
        if (mounted) {
          displayMessageToUser(
            "Registration successful! Check your email for the verification link.",
            context,
          );
          widget.onTap?.call();
        }
      } catch (e) {
        // pop loading circle
        if (mounted) Navigator.pop(context);

        // display error message to user
        if (mounted) displayMessageToUser(e.toString(), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // logo
                    Icon(
                      Icons.person_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),

                    const SizedBox(height: 25),

                    // app name
                    const Text(
                      "A I T O X R  U S E R",
                      style: TextStyle(fontSize: 20),
                    ),

                    const SizedBox(height: 50),

                    // username textfield
                    MyTextfield(
                      hintText: "Username",
                      obscureText: false,
                      controller: usernameController,
                    ),

                    const SizedBox(height: 10),

                    // textfield
                    MyTextfield(
                      hintText: "Email",
                      obscureText: false,
                      controller: emailController,
                    ),

                    const SizedBox(height: 10),

                    // password textfield
                    MyTextfield(
                      hintText: "Password",
                      obscureText: true,
                      controller: passwordController,
                    ),

                    const SizedBox(height: 10),

                    // confirm password textfield
                    MyTextfield(
                      hintText: "Confirm Password",
                      obscureText: true,
                      controller: confirmPasswordController,
                    ),

                    const SizedBox(height: 10),

                    const SizedBox(height: 25),

                    // register button
                    MyButton(text: "Register", onTap: registerUser),

                    const SizedBox(height: 25),

                    // don't have an account? Register here
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            "Login Here",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
