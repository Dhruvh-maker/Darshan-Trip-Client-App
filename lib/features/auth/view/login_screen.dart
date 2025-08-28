import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController phoneController;
  late TextEditingController passwordController;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // ✅ Logo
              Hero(
                tag: 'logo',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    "assets/logo.png",
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Welcome Back! 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login with OTP or Password",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 40),

              // 📱 Phone number input (with fixed +91)
              _buildPhoneInput(controller: phoneController),

              const SizedBox(height: 20),

              // 🔑 Password input
              _buildInputBox(
                icon: Icons.lock,
                hint: "Password",
                controller: passwordController,
                isPassword: true,
              ),

              const SizedBox(height: 30),

              // 📩 Send OTP button (Primary)
              _buildGradientButton(
                text: "Send OTP",
                icon: Icons.sms,
                loading: authVM.isLoading,
                onPressed: () {
                  String phone = phoneController.text.trim();
                  if (phone.isNotEmpty && phone.length == 10) {
                    // 🔥 This will check Firestore first, then send OTP
                    authVM.sendOTP(context, "+91$phone");
                  } else {
                    _showSnack(
                      context,
                      "Enter valid 10-digit phone number",
                      Colors.red,
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // 🔐 Login with Password button (Alternative)
              _buildGradientButton(
                text: "Login with Password",
                icon: Icons.lock_open,
                loading: authVM.isLoading,
                gradient: [Colors.green.shade500, Colors.green.shade600],
                onPressed: () {
                  String phone = phoneController.text.trim();
                  String password = passwordController.text.trim();

                  if (phone.isEmpty || phone.length != 10) {
                    _showSnack(
                      context,
                      "Enter valid 10-digit phone number",
                      Colors.red,
                    );
                  } else if (password.isEmpty) {
                    _showSnack(context, "Enter password", Colors.red);
                  } else {
                    authVM.loginWithPassword(context, phone, password);
                  }
                },
              ),

              const SizedBox(height: 30),

              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "OR",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 20),

              // Signup navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Phone input box (with fixed +91)
  Widget _buildPhoneInput({required TextEditingController controller}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Colors.orange.shade600),
          const SizedBox(width: 8),

          // ✅ Fixed +91
          Text(
            "+91",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),

          // 📱 Input field
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Phone Number",
                counterText: "",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Generic input box (used for password etc.)
  Widget _buildInputBox({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible, // 👈 Toggle visibility
        keyboardType: isPassword ? TextInputType.text : TextInputType.phone,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          counterText: "",
          icon: Icon(icon, color: Colors.orange.shade600),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  // 🔹 Gradient button widget
  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required bool loading,
    required VoidCallback onPressed,
    List<Color>? gradient,
  }) {
    final buttonGradient =
        gradient ?? [Colors.orange.shade500, Colors.orange.shade600];

    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: buttonGradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: buttonGradient.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // 🔹 Snackbar
  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
