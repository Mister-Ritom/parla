import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:parla/screens/email_auth.dart';
import 'package:parla/screens/home_screen.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return authProvider.isAuthenticated
            ? const HomeScreen()
            : const AuthScren();
      },
    );
  }
}

class AuthScren extends StatelessWidget {
  const AuthScren({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 300,
                child: RichText(
                  text: TextSpan(
                    text: 'Welcome to',
                    children: List.of([
                      TextSpan(
                        text: ' Parla',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: '!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ]),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            //Image of the app logo
            Image.asset('assets/Parla.png', height: 128),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle email login
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmailAuth()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    FontAwesomeIcons.envelope,
                  ), // Replace with appropriate icon
                  const SizedBox(width: 10),
                  const Text('Continue with Email'),
                ],
              ),
            ),
            SizedBox(height: 10),
            //line
            const Text(
              'Or',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    FontAwesomeIcons.google,
                  ), // Replace with appropriate icon
                  const SizedBox(width: 10),
                  const Text('Continue with Google'),
                ],
              ),
              onPressed: () {
                // Handle Google login
              },
            ),
            SizedBox(height: 10),
            Visibility(
              //show only if its ios ipad os or macos
              visible:
                  Theme.of(context).platform == TargetPlatform.iOS ||
                  Theme.of(context).platform == TargetPlatform.macOS,
              child: ElevatedButton(
                onPressed: () {
                  // Handle Apple login
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      FontAwesomeIcons.apple,
                    ), // Replace with appropriate icon
                    const SizedBox(width: 10),
                    const Text('Continue with Apple'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
