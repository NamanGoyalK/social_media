import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/button.dart';
import '../components/textfield.dart';
import '../helper/helper_functions.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // text controller
  final TextEditingController emailController = TextEditingController();

  // loading state
  bool isLoading = false;
  bool emailSent = false;

  // send reset email function
  void sendResetEmail() async {
    if (emailController.text.isEmpty) {
      displayMessageToUser("Please enter your email address", context);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        emailController.text.trim(),
      );

      setState(() {
        emailSent = true;
        isLoading = false;
      });

      if (mounted) {
        displayMessageToUser(
          "Password reset email sent! Please check your inbox.",
          context,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        displayMessageToUser(
          "Error sending reset email: ${e.toString()}",
          context,
        );
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // icon
                  Icon(
                    Icons.lock_reset_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),

                  const SizedBox(height: 25),

                  // title
                  const Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // subtitle
                  Text(
                    emailSent
                        ? "Reset link sent to your email!"
                        : "Enter your email address and we'll send you a link to reset your password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),

                  const SizedBox(height: 50),

                  if (!emailSent) ...[
                    // email textfield
                    MyTextfield(
                      hintText: "Enter your email",
                      obscureText: false,
                      controller: emailController,
                    ),

                    const SizedBox(height: 25),

                    // send reset email button
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : MyButton(
                          text: "Send Reset Email",
                          onTap: sendResetEmail,
                        ),
                  ] else ...[
                    // success icon
                    Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),

                    const SizedBox(height: 25),

                    // resend button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          emailSent = false;
                        });
                      },
                      child: const Text(
                        "Send Again",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 25),

                  // back to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Remember your password?",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Back to Login",
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
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
