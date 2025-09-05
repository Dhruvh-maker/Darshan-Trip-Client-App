import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  List<String> kutiyaLocations = [];
  bool isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _fetchKutiyaLocations();
  }

  Future<void> _fetchKutiyaLocations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("kutiyaLocations")
          .get();

      setState(() {
        kutiyaLocations = snapshot.docs
            .map((doc) => doc['kutiyaName'].toString())
            .toList();
        isLoadingLocations = false;
      });
    } catch (e) {
      print("❌ Error fetching kutiya locations: $e");
      setState(() {
        isLoadingLocations = false;
      });
    }
  }

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
              const SizedBox(height: 30),

              // Full Name
              _buildTextField(
                controller: nameController,
                labelText: "Full Name",
                prefixIcon: Icons.person,
                textInputType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // Age
              _buildTextField(
                controller: ageController,
                labelText: "Age",
                prefixIcon: Icons.cake,
                textInputType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Gender
              _buildDropdown<String>(
                label: "Gender",
                value: selectedGender,
                items: ['Male', 'Female', 'Other'],
                icon: Icons.person_outline,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // 🔹 Kutiya Location - dynamic fetch
              isLoadingLocations
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdown<String>(
                      label: "Aashram/Kutiya Location",
                      value: selectedKutiya,
                      items: kutiyaLocations,
                      icon: Icons.location_on,
                      onChanged: (value) {
                        setState(() {
                          selectedKutiya = value;
                        });
                      },
                    ),
              const SizedBox(height: 20),

              // Email
              _buildTextField(
                controller: emailController,
                labelText: "Email I.D.",
                prefixIcon: Icons.email,
                textInputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Phone
              _buildTextField(
                controller: phoneController,
                labelText: "Phone Number",
                prefixIcon: Icons.phone,
                textInputType: TextInputType.phone,
                prefixText: "+91 ",
              ),
              const SizedBox(height: 20),

              // Password
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
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Signup button
              ElevatedButton(
                onPressed: () {
                  if (selectedKutiya == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Select a Kutiya!")),
                    );
                    return;
                  }
                  authVM.signUpDirectly(
                    context,
                    name: nameController.text.trim(),
                    age: ageController.text.trim(),
                    gender: selectedGender ?? "",
                    kutiName: selectedKutiya!,
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    password: passwordController.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: labelText,
          prefixText: prefixText,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(prefixIcon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required IconData icon,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
