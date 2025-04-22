import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:provider/provider.dart';

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
  final _usernameController = TextEditingController();

  String errorMessage = '';
  bool usernameTaken = false;
  bool isLoading = false;
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
    return true;
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool isUsername = false,
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
                : isUsername && usernameTaken
                ? const Icon(Icons.error, color: Colors.red)
                : isUsername && !usernameTaken
                ? const Icon(Icons.check, color: Colors.green)
                : null,
        labelText: label,
        errorText: errorMessage.isNotEmpty ? errorMessage : null,
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
      isLoading = true;
      errorMessage = '';
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!isValid(email, password)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.signInWithEmailAndPassword(email, password);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMessage = 'Invalid email or password');
      return;
    }
  }

  Future<void> handleRegistration() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      usernameTaken = false;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (!isValid(email, password)) return;

    if (password != confirm) {
      setState(() {
        errorMessage = 'Passwords do not match';
        isLoading = false;
      });
      return;
    }
    if (name.isEmpty) {
      setState(() {
        errorMessage = 'Name is required';
        isLoading = false;
      });
      return;
    }
    if (username.isEmpty) {
      setState(() {
        errorMessage = 'Username is required';
        isLoading = false;
      });
      return;
    }

    //Check if username is already taken
    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
    if (query.docs.isNotEmpty) {
      setState(() {
        usernameTaken = true;
        isLoading = false;
      });
      return;
    }

    try {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.registerWithEmailAndPassword(email, password, {
        'name': name,
        'email': email,
        'username': username,
        'createdAt': DateTime.now(),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        errorMessage = 'Registration failed';
        isLoading = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !isLoading,
      replacement: const Center(child: CircularProgressIndicator()),
      child: DefaultTabController(
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
        buildTextField(
          controller: _usernameController,
          label: 'Username',
          isUsername: true,
        ),
        const SizedBox(height: 10),
        if (usernameTaken)
          const Text(
            'Username already taken',
            style: TextStyle(color: Colors.red),
          ),
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
