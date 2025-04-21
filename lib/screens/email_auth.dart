import 'package:flutter/material.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailAuth extends StatefulWidget {
  const EmailAuth({super.key});

  @override
  State<EmailAuth> createState() => _EmailAuthState();
}

class _EmailAuthState extends State<EmailAuth> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool isControllerValid(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return false;
    }
    //regex for email validation
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailPattern);
    if (!regex.hasMatch(email)) {
      String errorMessage = 'Please enter a valid email address';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
    // Check if password is at least 8 characters long with onen uppercase letter, one lowercase letter, one number and one special character
    String passwordPattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$';
    RegExp passwordRegex = RegExp(passwordPattern);
    if (!passwordRegex.hasMatch(password)) {
      String errorMessage =
          'Password must be at least 8 characters long, contain at least one uppercase letter,'
          'one lowercase letter, one number and one special character';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(title: const Text('Email Authentication')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RichText(
                text: TextSpan(
                  text: 'Hey 👋 \n',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Join the ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextSpan(
                      text: 'Encrypted',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: ' World now',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                dividerColor: Colors.transparent,
                labelColor: Theme.of(context).focusColor,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(
                    context,
                  ).focusColor.withValues(alpha: 0.2), // soft color
                ),
                tabs: [
                  Tab(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.lock),
                            const SizedBox(width: 10),
                            Text(
                              'Old User',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person_add),
                            const SizedBox(width: 10),
                            Text(
                              'New Account',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      child: Column(children: loginScreenWidgets(context)),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: registrationScreenWidgets(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> registrationScreenWidgets(BuildContext context) {
    return [
      TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Name',
          border: InputBorder.none,
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              width: 2.0,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      ...emailAndPassWidget(),
      const SizedBox(height: 10),
      TextField(
        controller: _confirmPasswordController,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          border: InputBorder.none,
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              width: 2.0,
            ),
          ),
        ),
        obscureText: true,
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () async {
          // Handle registration
          final email = _emailController.text;
          final password = _passwordController.text;
          final confirmPassword = _confirmPasswordController.text;
          final name = _nameController.text;

          if (isControllerValid(email, password)) {
            if (password != confirmPassword) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Passwords do not match')),
              );
              return;
            }
            //get auth provider from context
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            User? user = await authProvider.signUp(email, password, {
              'display_name': name,
              'username':
                  '$name${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
            });
            if (mounted && context.mounted) {
              if (user == null) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid email or password')),
                );
              } else {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registration successful')),
                );
                // Navigate to home screen
                Navigator.pop(context);
              }
            }
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter your email and password'),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).focusColor,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Register with Email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward, size: 24, color: Colors.white),
          ],
        ),
      ),
    ];
  }

  List<Widget> loginScreenWidgets(BuildContext context) {
    return [
      ...emailAndPassWidget(),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () async {
          // Handle login
          final email = _emailController.text;
          final password = _passwordController.text;

          if (isControllerValid(email, password)) {
            //get auth provider from context
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            User? user = await authProvider.signIn(email, password);
            if (mounted && context.mounted) {
              if (user == null) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid email or password')),
                );
              } else {
                Navigator.pop(context);
              }
            }
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter your email and password'),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login with Email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward, size: 24, color: Colors.white),
          ],
        ),
      ),
      const SizedBox(height: 20),
      TextButton(
        onPressed: () {
          // Handle sign up
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Text("Forgot Password? Reset it here"),
      ),
    ];
  }

  List<Widget> emailAndPassWidget() {
    return [
      TextField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          border: InputBorder.none,
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              width: 2.0,
            ),
          ),
        ),
      ),
      //A divider with a centered line
      const SizedBox(height: 10),
      Center(
        child: Container(
          width: 60, // ⬅️ short line
          height: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Password',
          border: InputBorder.none,
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              width: 2.0,
            ),
          ),
        ),
        obscureText: true,
      ),
    ];
  }
}
