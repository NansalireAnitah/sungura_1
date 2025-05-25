import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'package:front_end/screens/home_screen.dart';
import 'package:front_end/screens/menu_screen.dart';

class SignUpScreen extends StatefulWidget {
  final bool isEditing;

  const SignUpScreen({
    super.key,
    required this.isEditing,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? '';
          _emailController.text = user.email ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required IconData icon,
    required String labelText,
    required TextEditingController controller,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        validator: validator ?? (value) => value?.isEmpty ?? true ? "$labelText is required" : null,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        validator: _validatePassword,
        decoration: InputDecoration(
          labelText: widget.isEditing ? "New Password (optional)" : "Password",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.lock, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[50],
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (widget.isEditing && (value == null || value.isEmpty)) return null;
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 8) return "Password must be at least 8 characters";
    if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).+$').hasMatch(value)) {
      return "Must include uppercase, lowercase and number";
    }
    return null;
  }

  Widget _buildConfirmPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: !_isConfirmPasswordVisible,
        validator: _validateConfirmPassword,
        decoration: InputDecoration(
          labelText: widget.isEditing
              ? "Confirm New Password"
              : "Confirm Password",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.lock, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[50],
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
        ),
      ),
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (widget.isEditing && _passwordController.text.isEmpty) return null;
    if (value == null || value.isEmpty) return "Please confirm password";
    if (value != _passwordController.text) return "Passwords don't match";
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

      if (widget.isEditing) {
        await _updateProfile(authProvider);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        await authProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      case 'requires-recent-login':
        return 'Please login again to update email/password';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _updateProfile(MyAuthProvider authProvider) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Update name in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'name': _nameController.text.trim()});

    // Update email if changed
    if (_emailController.text.trim() != user.email) {
      await user.updateEmail(_emailController.text.trim());
    }

    // Update password if provided
    if (_passwordController.text.isNotEmpty) {
      await user.updatePassword(_passwordController.text);
    }

    // Update auth provider state
    authProvider.syncWithFirebaseUser(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: Text(widget.isEditing ? 'Edit Profile' : 'Sign Up'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1513104890138-7c749659a584?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black54,
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          widget.isEditing ? 'Update Your Profile' : 'Create Account',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isEditing
                              ? 'Manage your account details'
                              : 'Get started with Sungura',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          icon: Icons.person,
                          labelText: 'Full Name',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          maxLength: 30,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          icon: Icons.email,
                          labelText: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email is required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 16),
                        _buildConfirmPasswordField(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(widget.isEditing ? 'SAVE CHANGES' : 'SIGN UP'),
                          ),
                        ),
                        if (!widget.isEditing) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}