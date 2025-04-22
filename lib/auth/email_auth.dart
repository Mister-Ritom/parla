import 'package:flutter/foundation.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  String errorMessage = '';
  bool showPassword = false;

  bool isValid(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Email and password are required.');
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      setState(() => errorMessage = 'Please enter a valid email address.');
      return false;
    }

    if (!passwordRegex.hasMatch(password)) {
      setState(
        () =>
            errorMessage =
                'Password must be at least 8 characters, include upper/lowercase, a number, and a symbol.',
      );
      return false;
    }

    setState(() => errorMessage = '');
    return true;
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !showPassword,
      decoration: InputDecoration(
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                )
                : null,
        labelText: label,
        errorText:
            errorMessage.isNotEmpty &&
                    (label == 'Email' ||
                        label == 'Password' ||
                        (isConfirmPassword &&
                            _passwordController.text !=
                                _confirmPasswordController.text))
                ? errorMessage
                : null,
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> handleLogin() async {
    setState(() {
      errorMessage = "loading";
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!isValid(email, password)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    User? user = await authProvider.signIn(email, password);

    if (!mounted) return;

    if (user == null) {
      setState(() => errorMessage = 'Invalid email or password');
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> handleRegistration() async {
    setState(() {
      errorMessage = "loading";
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    if (!isValid(email, password)) return;

    if (password != confirm) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }
    if (name.isEmpty) {
      setState(() => errorMessage = 'Name is required');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    User? user = await authProvider.signUp(email, password, {
      'display_name': name,
    });
    if (user == null) {
      throw "Something went wrong; user is null";
    }
    //add the userdata to a profiles collection in supabase database
    final supabase = Supabase.instance.client;

    final response = await supabase.from('profiles').insert({
      'user_id': user.id,
      'email': email,
      'display_name': name,
      'username':
          '$name${(100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString().substring(0, 6)}',
    });

    if (response != null && response.error != null) {
      setState(
        () =>
            errorMessage =
                'Failed to save user profile: ${response.error!.message}',
      );
      return;
    }

    if (!mounted) return;

    setState(() => errorMessage = '');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage == "loading") {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Email Authentication')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              RichText(
                text: TextSpan(
                  text: 'Hey 👋\n',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Join the ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextSpan(
                      text: 'Encrypted ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'World now',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).focusColor.withValues(alpha: 0.2),
                ),
                tabs: [
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      width: 128,
                      height: 64,
                      child: Tab(icon: Icon(Icons.lock), text: 'Old User'),
                    ),
                  ),
                  Card(
                    child: Container(
                      width: 128,
                      height: 64,
                      padding: EdgeInsets.all(8),
                      child: Tab(
                        icon: Icon(Icons.person_add),
                        text: 'New Account',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [buildLoginTab(), buildRegisterTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoginTab() {
    return ListView(
      children: [
        buildTextField(controller: _emailController, label: 'Email'),
        const SizedBox(height: 10),
        buildTextField(
          controller: _passwordController,
          label: 'Password',
          isPassword: true,
        ),
        const SizedBox(height: 20),
        buildActionButton(
          'Login with Email',
          handleLogin,
          Theme.of(context).colorScheme.secondary,
        ),
        TextButton(
          onPressed: () {},
          child: const Text("Forgot Password? Reset it here"),
        ),
      ],
    );
  }

  Widget buildRegisterTab() {
    return ListView(
      children: [
        buildTextField(controller: _nameController, label: 'Name'),
        const SizedBox(height: 10),
        buildTextField(controller: _emailController, label: 'Email'),
        const SizedBox(height: 10),
        buildTextField(
          controller: _passwordController,
          label: 'Password',
          isPassword: true,
        ),
        const SizedBox(height: 10),
        buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          isPassword: true,
          isConfirmPassword: true,
        ),
        const SizedBox(height: 20),
        buildActionButton(
          'Register with Email',
          handleRegistration,
          Theme.of(context).focusColor,
        ),
      ],
    );
  }

  Widget buildActionButton(String text, VoidCallback onPressed, Color bgColor) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }
}
