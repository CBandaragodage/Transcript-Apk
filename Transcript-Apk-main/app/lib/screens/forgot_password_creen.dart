import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ForgotPasswordScreen(),
    ),
  );
}

// ==========================================
// 1. DESIGN SYSTEM / COLOR PALETTE
// ==========================================
class AppTheme {
  static const Color background = Color(0xFF0D131D);
  static const Color cardBg = Color(0xFF131B26);
  static const Color inputBg = Color(0xFF111721);
  static const Color border = Color(0xFF1F2A38);

  static const Color primaryBlue = Color(0xFF0075E1);
  static const Color iconBlueBg = Color(0xFF11253E);
  static const Color iconBlue = Color(0xFF60A5FA);

  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8B98A9);
}

// ==========================================
// 2. FORGOT PASSWORD SCREEN
// ==========================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "Reset Password",
          style: TextStyle(
            color: AppTheme.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.border,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Lock Icon Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.iconBlueBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppTheme.iconBlue,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Instructions Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Enter your registered email address to receive a password reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Email Input Field Label
              const Text(
                "Email Address",
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // Input TextField
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: "name@example.com",
                    hintStyle: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const Spacer(),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Send Reset Code Action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "SEND RESET CODE",
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: AppTheme.textWhite, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}