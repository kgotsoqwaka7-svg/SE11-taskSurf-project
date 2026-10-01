import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/authentication_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/main_navigation.dart';

import 'homeScreen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  // Selected registration role
  String selectedRole = '';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  void switchMode(bool login) {
    setState(() {
      isLogin = login;
    });
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please enter your email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 1. Fetch the user's role from your database
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).get();
      String role = doc['role'] ?? 'findWork';

      if (!mounted) return;

      // 2. Route them to the correct dashboard based on their role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => (role == 'postTasks' || role == 'Provider') 
              ? const MainNavigation() 
              : const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      }

      showMessage(message);
    } catch (e) {
      showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Check required fields
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Please complete all fields.');
      return;
    }

    // Check role
    if (selectedRole.isEmpty) {
      showMessage('Please select Find Work or Post Tasks.');
      return;
    }

    // Check passwords
    if (password != confirmPassword) {
      showMessage('Passwords do not match.');
      return;
    }

    // Firebase requires at least 6 characters
    if (password.length < 6) {
      showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // WITH THIS 1 LINE:
      await AuthenticationService().registerUser(name: name, email: email, password: password, role: selectedRole);

     if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => (selectedRole == 'postTasks' || selectedRole == 'Provider') 
              ? const MainNavigation() 
              : const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';

      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Please choose a stronger password.';
      }

      showMessage(message);
    } catch (e) {
      showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Enter your email address first.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      showMessage('Password reset email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      String message = 'Could not send password reset email.';

      if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      }

      showMessage(message);
    } catch (e) {
      showMessage('Something went wrong. Please try again.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return SizedBox(
                  height: 330,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: AuthWavePainter(
                      animationValue: _waveController.value,
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/tasksurfLogo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    const Text(
                      'TaskSurf',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Ride the wave to your next task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 58),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              isLogin ? 'Welcome Back' : 'Create Your Account',
                              key: ValueKey(isLogin),
                              style: const TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              isLogin
                                  ? 'Sign in to continue'
                                  : 'Join TaskSurf and ride the wave',
                              key: ValueKey('subtitle_$isLogin'),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          Container(
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _buildToggleButton(
                                  title: 'Sign In',
                                  selected: isLogin,
                                  onTap: () => switchMode(true),
                                ),
                                _buildToggleButton(
                                  title: 'Create Account',
                                  selected: !isLogin,
                                  onTap: () => switchMode(false),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          if (isLogin) ...[
                            _buildLabel('Email'),

                            const SizedBox(height: 8),

                            _buildTextField(
                              controller: emailController,
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 18),

                            _buildLabel('Password'),

                            const SizedBox(height: 8),

                            _buildPasswordField(
                              controller: passwordController,
                              hint: 'Enter your password',
                              obscureText: obscurePassword,
                              onToggle: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading ? null : resetPassword,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Color(0xFF1769F5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            _buildMainButton(
                              text: 'Sign In',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: login,
                            ),

                            const SizedBox(height: 22),

                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => switchMode(false),
                                        child: const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            color: Color(0xFF1769F5),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            _buildLabel('Full Name'),

                            const SizedBox(height: 8),

                            _buildTextField(
                              controller: nameController,
                              hint: 'Enter your full name',
                              icon: Icons.person_outline,
                            ),

                            const SizedBox(height: 18),

                            _buildLabel('I WANT TO'),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildChoiceButton(
                                    title: 'Find Work',
                                    icon: Icons.work_outline,
                                    role: 'findWork',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildChoiceButton(
                                    title: 'Post Tasks',
                                    icon: Icons.add_task,
                                    role: 'postTasks',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            _buildLabel('Email'),

                            const SizedBox(height: 8),

                            _buildTextField(
                              controller: emailController,
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 18),

                            _buildLabel('Password'),

                            const SizedBox(height: 8),

                            _buildPasswordField(
                              controller: passwordController,
                              hint: 'Create a password',
                              obscureText: obscurePassword,
                              onToggle: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),

                            const SizedBox(height: 18),

                            _buildLabel('Confirm Password'),

                            const SizedBox(height: 8),

                            _buildPasswordField(
                              controller: confirmPasswordController,
                              hint: 'Confirm your password',
                              obscureText: obscureConfirmPassword,
                              onToggle: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),

                            const SizedBox(height: 24),

                            _buildMainButton(
                              text: 'Create My Account',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: register,
                            ),

                            const SizedBox(height: 22),

                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => switchMode(true),
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: Color(0xFF1769F5),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 42,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF1769F5)
                    : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !isLoading,
      style: const TextStyle(color: Color(0xFF172033), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF1769F5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: !isLoading,
      style: const TextStyle(color: Color(0xFF172033), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF64748B),
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: isLoading ? null : onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF64748B),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF1769F5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1769F5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF1769F5).withOpacity(0.65),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 19),
                ],
              ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required String title,
    required IconData icon,
    required String role,
  }) {
    final bool selected = selectedRole == role;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              setState(() {
                selectedRole = role;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? const Color(0xFF1769F5) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? const Color(0xFF1769F5)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF1769F5)
                    : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWavePainter extends CustomPainter {
  final double animationValue;

  AuthWavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF1769F5)
      ..style = PaintingStyle.fill;

    final Path bluePath = Path();

    bluePath.moveTo(0, 0);
    bluePath.lineTo(size.width, 0);

    bluePath.lineTo(size.width, size.height * 0.72);

    for (double x = size.width; x >= 0; x -= 5) {
      final double normalizedX = x / size.width;

      final double wave = math.sin(
        (normalizedX * 2 * math.pi) + (animationValue * 2 * math.pi),
      );

      final double y = size.height * 0.72 + (wave * 9);

      bluePath.lineTo(x, y);
    }

    bluePath.close();

    canvas.drawPath(bluePath, bluePaint);

    final Paint lightPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final Path lightPath = Path();

    lightPath.moveTo(0, 0);
    lightPath.lineTo(size.width, 0);

    lightPath.lineTo(size.width, size.height * 0.78);

    for (double x = size.width; x >= 0; x -= 5) {
      final double normalizedX = x / size.width;

      final double wave = math.sin(
        (normalizedX * 2 * math.pi) + (animationValue * 2 * math.pi) + 1.5,
      );

      final double y = size.height * 0.78 + (wave * 7);

      lightPath.lineTo(x, y);
    }

    lightPath.close();

    canvas.drawPath(lightPath, lightPaint);
  }

  @override
  bool shouldRepaint(covariant AuthWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}