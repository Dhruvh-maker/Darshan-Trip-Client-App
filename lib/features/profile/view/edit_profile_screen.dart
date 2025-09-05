import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for input formatters
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodel/profile_screen_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  // Removed _genderController as we'll use dropdown
  late TextEditingController _ageController;
  late TextEditingController _contactController;

  final _formKey = GlobalKey<FormState>();
  bool _controllersInitialized = false;

  // Gender dropdown
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female'];

  // Kutiya dropdown
  String? _selectedKutiya;
  List<String> _kutiyaLocations = [];
  bool _isLoadingKutiya = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _ageController = TextEditingController();
    _contactController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
      _fetchKutiyaLocations();
    });
  }

  Future<void> _fetchKutiyaLocations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("kutiyaLocations")
          .get();

      setState(() {
        _kutiyaLocations = snapshot.docs
            .map((doc) => doc['kutiyaName'].toString())
            .toList();
        _isLoadingKutiya = false;
      });
    } catch (e) {
      print("❌ Error fetching kutiya locations: $e");
      setState(() {
        _isLoadingKutiya = false;
      });
    }
  }

  void _initializeControllers() {
    final viewModel = Provider.of<ProfileScreenViewModel>(
      context,
      listen: false,
    );

    if (!viewModel.isLoading) {
      _setControllerValues(viewModel);
    } else {
      void listener() {
        if (!viewModel.isLoading && mounted) {
          viewModel.removeListener(listener);
          _setControllerValues(viewModel);
        }
      }

      viewModel.addListener(listener);
    }
  }

  void _setControllerValues(ProfileScreenViewModel viewModel) {
    if (mounted && !_controllersInitialized) {
      setState(() {
        _nameController.text = viewModel.userName != "Loading..."
            ? viewModel.userName
            : "";
        _emailController.text = viewModel.email != "Loading..."
            ? viewModel.email
            : "";

        // Set gender dropdown value
        _selectedGender =
            viewModel.gender != "Loading..." && viewModel.gender.isNotEmpty
            ? viewModel.gender
            : null;

        _ageController.text = viewModel.age != "Loading..."
            ? viewModel.age
            : "";
        _contactController.text = viewModel.contactNumber != "Loading..."
            ? viewModel.contactNumber
            : "";

        _selectedKutiya = viewModel.kutiName != "Loading..."
            ? viewModel.kutiName
            : null;

        _controllersInitialized = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate gender selection
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select gender"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final viewModel = Provider.of<ProfileScreenViewModel>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF5A623)),
        ),
      ),
    );

    try {
      await viewModel.updatePersonalInfo(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _selectedGender!, // Use selected gender instead of controller text
        _ageController.text.trim(),
        _contactController.text.trim(),
        _selectedKutiya ?? viewModel.kutiName,
      );

      Navigator.pop(context); // close loader

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileScreenViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              "Edit Profile",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFF5A623),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 🔹 Gradient Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF5A623), Color(0xFFF76C38)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage(viewModel.profileImage),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Update your profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Form
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          labelText: "Full Name",
                          prefixIcon: Icons.person,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          labelText: "Email Address",
                          prefixIcon: Icons.email,
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Gender Dropdown (replacing text field)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: "Gender",
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5A623),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.male,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 16,
                              ),
                            ),
                            items: _genderOptions
                                .map(
                                  (gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedGender = val;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select gender';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _ageController,
                          labelText: "Age",
                          prefixIcon: Icons.cake,
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Contact Number with 10 digit limit
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _contactController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: "Contact Number",
                              labelStyle: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5A623),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter contact number';
                              }
                              if (value.length != 10) {
                                return 'Contact number must be exactly 10 digits';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 🔹 Kutiya Dropdown
                        _isLoadingKutiya
                            ? const CircularProgressIndicator()
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedKutiya,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    labelText: "Aashram/Kutiya Location",
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(12),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5A623),
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
                                  items: _kutiyaLocations
                                      .map(
                                        (loc) => DropdownMenuItem(
                                          value: loc,
                                          child: Text(loc),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedKutiya = val;
                                    });
                                  },
                                ),
                              ),

                        const SizedBox(height: 40),

                        // 🔹 Save Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5A623), Color(0xFFF76C38)],
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
                            onPressed: _controllersInitialized
                                ? _saveChanges
                                : null,
                            child: const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(prefixIcon, color: Colors.white, size: 20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $labelText';
          }
          return null;
        },
      ),
    );
  }
}
