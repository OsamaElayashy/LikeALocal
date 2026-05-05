import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    // Basic validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await AuthService().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (user != null) {
      Provider.of<AppProvider>(context, listen: false).setUser(user);
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Header
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue exploring',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: Color(0xFF6B7280), size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Color(0xFF6B7280), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF6B7280),
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Sign In',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),

              // Divider
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 24),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: Color(0xFF6B7280))),
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushNamed('/register'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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