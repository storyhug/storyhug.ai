import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/slogan_service.dart';
import '../../../shared/widgets/storyhug_background.dart';
import '../../../shared/responsive.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _currentSlogan = '';
  
  final AuthService _authService = AuthService();
  final SloganService _sloganService = SloganService();

  @override
  void initState() {
    super.initState();
    _currentSlogan = _sloganService.getCurrentSlogan();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final double gapS = Responsive.spacingSmall(context);
    final double gapM = Responsive.spacingMedium(context);
    final double gapL = Responsive.spacingLarge(context);
    final double cardWidthFactor = Responsive.cardWidthFactor(context);
    final double logoSize = Responsive.logoSize(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: StoryHugBackground(
        showStars: true,
        animateStars: false,
        child: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: gapM, vertical: gapS),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.04),
                            // App Logo - StoryHug Logo (responsive size with rounded corners)
                            Center(
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(logoSize * 0.3 * 0.6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      blurRadius: logoSize * 0.14 * 0.6,
                                      offset: Offset(0, logoSize * 0.07 * 0.6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(logoSize * 0.3 * 0.6),
                                  child: Image.asset(
                                    'assets/branding/storyhug_logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to icon if logo fails to load
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(logoSize * 0.3 * 0.6),
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.auto_stories,
                                          size: logoSize * 0.5 * 0.6,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: gapL),
                            // Form card with responsive width
                            Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: FractionallySizedBox(
                                  widthFactor: 0.9,
                                  child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: EdgeInsets.all(gapM + 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF6D62D8).withOpacity(0.75),
                                            const Color(0xFF8B7ED8).withOpacity(0.9),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 30,
                                            offset: const Offset(0, 15),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(50),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: _AuthTab(
                                                      label: 'Sign Up',
                                                      isActive: _isSignUp,
                                                      onTap: () { if (!_isSignUp) setState(() => _isSignUp = true); },
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: _AuthTab(
                                                      label: 'Log In',
                                                      isActive: !_isSignUp,
                                                      onTap: () { if (_isSignUp) setState(() => _isSignUp = false); },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: gapM),
                                          Form(
                                            key: _formKey,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                if (_isSignUp) ...[
                                                  _FrostedTextField(
                                                    controller: _nameController,
                                                    hintText: 'Full Name',
                                                    icon: Icons.person,
                                                    textCapitalization: TextCapitalization.words,
                                                    validator: (value) {
                                                      if (_isSignUp) {
                                                        if (value == null || value.trim().isEmpty) return 'Please enter your name';
                                                        if (value.trim().length < 2) return 'Name must be at least 2 characters';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                  SizedBox(height: gapS + 4),
                                                ],
                                                _FrostedTextField(
                                                  controller: _emailController,
                                                  hintText: 'Email Address',
                                                  icon: Icons.email,
                                                  keyboardType: TextInputType.emailAddress,
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return 'Please enter your email';
                                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email';
                                                    return null;
                                                  },
                                                ),
                                                SizedBox(height: gapS + 4),
                                                _FrostedTextField(
                                                  controller: _passwordController,
                                                  hintText: 'Password',
                                                  icon: Icons.lock,
                                                  obscureText: _obscurePassword,
                                                  suffix: IconButton(
                                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.black54),
                                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return 'Please enter your password';
                                                    if (_isSignUp && value.length < 6) return 'Password must be at least 6 characters';
                                                    return null;
                                                  },
                                                ),
                                                if (!_isSignUp)
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: TextButton(
                                                      onPressed: _handleForgotPassword,
                                                      child: const Text('Forgot Password?', style: TextStyle(color: Colors.white70)),
                                                    ),
                                                  ),
                                                SizedBox(height: gapS),
                                                SizedBox(
                                                  height: 56,
                                                  child: _YellowButton(
                                                    label: _isSignUp ? 'SIGN UP' : 'LOG IN',
                                                    onPressed: _isLoading ? null : _handleAuth,
                                                    isLoading: _isLoading,
                                                  ),
                                                ),
                                                SizedBox(height: gapM - 2),
                                                const Center(child: Text('Or continue with', style: TextStyle(color: Colors.white70))),
                                                SizedBox(height: gapS + 4),
                                                Row(
                                                  children: [
                                                    Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata, onTap: _isLoading ? null : _handleGoogleSignIn)),
                                                    SizedBox(width: gapS + 4),
                                                    Expanded(child: _SocialButton(label: 'Apple', icon: Icons.apple, onTap: _isLoading ? null : _handleAppleSignIn)),
                                                  ],
                                                ),
                                                SizedBox(height: gapS + 4),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(_isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ', style: const TextStyle(color: Colors.white70)),
                                                    TextButton(onPressed: () => setState(() => _isSignUp = !_isSignUp), child: Text(_isSignUp ? 'Log In' : 'Sign Up')),
                                                  ],
                                                ),
                                                if (_isSignUp) ...[
                                                  SizedBox(height: gapS),
                                                  RichText(
                                                    textAlign: TextAlign.center,
                                                    text: TextSpan(
                                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                      children: [
                                                        const TextSpan(text: 'By signing up, you agree to our '),
                                                        TextSpan(text: 'Terms', style: const TextStyle(decoration: TextDecoration.underline, color: Color(0xFF4EA3FF)), recognizer: TapGestureRecognizer()..onTap = () {}),
                                                        const TextSpan(text: ' & '),
                                                        TextSpan(text: 'Privacy Policy', style: const TextStyle(decoration: TextDecoration.underline, color: Color(0xFF4EA3FF)), recognizer: TapGestureRecognizer()..onTap = () {}),
                                                        const TextSpan(text: '.'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                    ),
                                  ),
                                ),
                              ),
                                ),
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.04),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        if (_isSignUp) {
          await _authService.signUp(_emailController.text, _passwordController.text, _nameController.text.trim());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created! Please check your email to verify.'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } else {
          await _authService.signIn(_emailController.text, _passwordController.text);
          if (mounted) {
            context.go('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signInWithApple();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple sign in failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    try {
      await _authService.resetPassword(_emailController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildSloganDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentSlogan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.auto_awesome,
            color: Colors.amber,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _AuthTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFD85A) : const Color(0xFFB9A9F2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD85A).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isActive ? Colors.black87 : const Color(0xFF4E3F8F),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FrostedTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 4,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA9A9A9)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(icon, color: Colors.black45),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}

class _YellowButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  const _YellowButton({required this.label, required this.onPressed, required this.isLoading});

  @override
  State<_YellowButton> createState() => _YellowButtonState();
}

class _YellowButtonState extends State<_YellowButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - (_controller.value * 0.03);
          return Transform.scale(
            scale: scale,
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD85A),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 6,
                shadowColor: const Color(0xFFFFD85A).withOpacity(0.6),
              ),
              child: widget.isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                  : Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _SocialButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: Colors.white),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

