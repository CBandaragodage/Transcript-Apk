import 'package:flutter/material.dart';
import 'dashboard_home_screen.dart'; // Ensure this points to your dashboard file

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Dark Navy Background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // White Rounded Square Logo Container
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      size: 38,
                      color: Color(0xFF0072CE),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Subtitle Header
                const Text(
                  'SLT VoiceNotes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bilingual Speech-to-Text Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 32),

                // Email Label & Input Field
                const Text(
                  'Email',
                  style: TextStyle(
                    color: Color(0xFFC9D1D9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(
                    hintText: 'name@company.com',
                    prefixIcon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 18),

                // Password Label & Input Field
                const Text(
                  'Password',
                  style: TextStyle(
                    color: Color(0xFFC9D1D9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF8B949E),
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordObscured = !_isPasswordObscured,
                      ),
                    ),
                  ),
                ),

                // Forgot Password Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset link sent to email!'),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF58A6FF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // LOG IN Button (Navigates to DashboardHomeScreen)
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      // Option A: Direct MaterialPageRoute Navigation (Recommended if not using routes table)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardHomeScreen(),
                        ),
                      );

                      // Option B: Named Route (Requires route setup in main.dart)
                      // Navigator.pushReplacementNamed(context, '/DashboardHomeScreen');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0072CE), // SLT Blue
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LOG IN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // OR Divider Line
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xFF30363D))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFF30363D))),
                  ],
                ),
                const SizedBox(height: 20),

                // Continue with Google Button
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardHomeScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF161B22),
                      side: const BorderSide(color: Color(0xFF30363D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'G',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Navigation Link to Sign Up Screen
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF58A6FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Helper for Input Fields styling
  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF484F58), fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xFF8B949E), size: 18)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF161B22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0072CE), width: 1.5),
      ),
    );
  }
}