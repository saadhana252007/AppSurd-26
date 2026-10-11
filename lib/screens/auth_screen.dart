import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter an email and a password of at least 6 characters.',
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final auth = Supabase.instance.client.auth;

      if (isLogin) {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        final response = await auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );

        if (response.session == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to confirm signup, then log in.'),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROOFLOCK')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Proof, not promises.',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Sign in to your account' : 'Create your account',
                  style: const TextStyle(color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (minimum 6 characters)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: Text(
                    loading
                        ? 'Please wait...'
                        : isLogin
                        ? 'Sign In'
                        : 'Sign Up',
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? 'New here? Create an account'
                        : 'Already registered? Sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
