import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  // Inline validation errors
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  bool _validate() {
    bool isValid = true;

    // Username: min 3 chars
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _usernameError = 'Username is required';
      isValid = false;
    } else if (username.length < 3) {
      _usernameError = 'Username must be at least 3 characters';
      isValid = false;
    } else {
      _usernameError = null;
    }

    // Email: valid format
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (email.isEmpty) {
      _emailError = 'Email is required';
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = 'Enter a valid email address';
      isValid = false;
    } else {
      _emailError = null;
    }

    // Password: min 6 chars
    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      isValid = false;
    } else {
      _passwordError = null;
    }

    setState(() {}); // Refresh UI with errors
    return isValid;
  }

  Future<void> _register() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.client.post(
        '/api/auth/register',
        data: {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(); // Go back to login screen
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response?.data['detail']
          : null;

      // Handle Pydantic validation errors (422)
      if (detail is List && detail.isNotEmpty) {
        final errorMessages = detail.map((d) {
          if (d is Map) return d['msg'] ?? 'Validation error';
          return d.toString();
        }).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessages)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(detail?.toString() ?? 'Registration failed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // ── Username Field ──────────────────────────────────────────────
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _usernameError,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                  ),
                ),
                onChanged: (_) {
                  if (_usernameError != null) {
                    setState(() => _usernameError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Email Field ─────────────────────────────────────────────────
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _emailError,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Password Field ──────────────────────────────────────────────
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _passwordError,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                  ),
                ),
                obscureText: true,
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF10B981), // Emerald
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
