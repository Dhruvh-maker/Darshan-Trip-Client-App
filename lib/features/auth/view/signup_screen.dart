import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final referralCodeController = TextEditingController();
  String? selectedGender;
  String? selectedKutiya;
  bool _obscurePassword = true;

  // List of Aashram/Kutiya locations (example values)
  final List<String> kutiyaLocations = [
    'Banarash',
    'Haridwar',
    'Rishikesh',
    'Vrindavan',
  ];

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Account",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.grey.shade700,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Hero(
                tag: 'logo',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    "assets/logo.png",
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb,
                          color: Colors.white,
                          size: 60,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Join Us Today!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Fill in your details to get started",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              // Full Name field
              _buildTextField(
                controller: nameController,
                labelText: "Full Name",
                prefixIcon: Icons.person,
                textInputType: TextInputType.text,
              ),

              const SizedBox(height: 20),

              // Age field
              _buildTextField(
                controller: ageController,
                labelText: "Age",
                prefixIcon: Icons.cake,
                textInputType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // Gender field
              // Gender field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: "Gender",
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map(
                        (gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a gender' : null,
                ),
              ),

              const SizedBox(height: 20),

              // Aashram/Kutiya Location field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedKutiya,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: "Aashram/Kutiya Location",
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                  ),
                  items: kutiyaLocations
                      .map(
                        (location) => DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedKutiya = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a location' : null,
                ),
              ),

              const SizedBox(height: 20),

              // Email field
              _buildTextField(
                controller: emailController,
                labelText: "Email I.D.",
                prefixIcon: Icons.email,
                textInputType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // Phone Number field
              _buildTextField(
                controller: phoneController,
                labelText: "Phone Number",
                prefixIcon: Icons.phone,
                textInputType: TextInputType.phone,
                prefixText: "+91 ",
              ),

              const SizedBox(height: 20),

              // Password field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Referral Code field
              _buildTextField(
                controller: referralCodeController,
                labelText: "Referral Code (Optional)",
                prefixIcon: Icons.card_giftcard,
                textInputType: TextInputType.text,
              ),

              const SizedBox(height: 30),

              // Sign Up button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade500, Colors.orange.shade700],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade300,
                      spreadRadius: 1,
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
                  onPressed: authVM.isLoading
                      ? null
                      : () {
                          final name = nameController.text.trim();
                          final age = ageController.text.trim();
                          final email = emailController.text.trim();
                          final phone = phoneController.text.trim();
                          final password = passwordController.text.trim();
                          final referralCode = referralCodeController.text
                              .trim();

                          // Enhanced validation
                          if (name.isEmpty) {
                            _showValidationError(
                              context,
                              "Please enter your full name",
                            );
                            return;
                          }
                          if (age.isEmpty || int.tryParse(age) == null) {
                            _showValidationError(
                              context,
                              "Please enter a valid age",
                            );
                            return;
                          }
                          if (selectedGender == null) {
                            _showValidationError(
                              context,
                              "Please select a gender",
                            );
                            return;
                          }
                          if (selectedKutiya == null) {
                            _showValidationError(
                              context,
                              "Please select an Aashram/Kutiya location",
                            );
                            return;
                          }
                          if (email.isEmpty ||
                              !RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(email)) {
                            _showValidationError(
                              context,
                              "Please enter a valid email address",
                            );
                            return;
                          }
                          if (phone.isEmpty || phone.length != 10) {
                            _showValidationError(
                              context,
                              "Please enter a valid 10-digit phone number",
                            );
                            return;
                          }
                          if (password.isEmpty || password.length < 6) {
                            _showValidationError(
                              context,
                              "Password must be at least 6 characters",
                            );
                            return;
                          }

                          // Direct signup without OTP
                          authVM.signUpDirectly(
                            context,
                            name: name,
                            age: age,
                            gender: selectedGender!,
                            kutiName: selectedKutiya!,
                            email: email,
                            phone: phone,
                            password: password,
                            referralCode: referralCode,
                          );
                        },
                  child: authVM.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // Terms and privacy notice
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.security, color: Colors.grey.shade600, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      "By creating an account, you agree to our Terms of Service and Privacy Policy",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required TextInputType textInputType,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: textInputType,
        maxLength: textInputType == TextInputType.phone ? 10 : null,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: labelText,
          prefixText: prefixText,
          counterText: "",
          prefixStyle: TextStyle(
            color: Colors.orange.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(prefixIcon, color: Colors.white, size: 20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    referralCodeController.dispose();
    super.dispose();
  }
}
