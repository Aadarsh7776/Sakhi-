import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_textfield.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFF4081,
      ), // 💖 Same pink background as Login
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🌸 Sakhi Logo
              Image.asset(
                'assets/sakhi_logo.png', // <-- Place your logo here
                height: 90,
              ),
              const SizedBox(height: 10),

              const Text(
                "Join Sakhi 💖",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // Full Name
              CustomTextField(
                hintText: 'Full Name',
                controller: nameController,
              ),

              // Email
              CustomTextField(
                hintText: 'Email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              // Password
              CustomTextField(
                hintText: 'Password',
                obscureText: true,
                controller: passwordController,
              ),

              const SizedBox(height: 20),

              // Register Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pinkAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  String name = nameController.text.trim();
                  String email = emailController.text.trim();
                  String password = passwordController.text.trim();

                  if (name.isEmpty || email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  try {
                    // ✅ Firebase Registration
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                    // ✅ Save user info to Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userCredential.user!.uid)
                        .set({
                          'name': name,
                          'email': email,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Account created successfully!"),
                      ),
                    );

                    // ✅ Navigate to Login Page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Registration Failed"),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Register', style: TextStyle(fontSize: 18)),
              ),

              const SizedBox(height: 20),

              // Already have account → Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Social Media Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/google.png'),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Image.asset('assets/facebook.jpg'),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Image.asset('assets/apple.jpg'),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
