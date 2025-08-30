import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/profile_screen_viewmodel.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _genderController;
  late TextEditingController _ageController;
  late TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<ProfileScreenViewModel>(
      context,
      listen: false,
    );
    _nameController = TextEditingController(text: viewModel.userName);
    _emailController = TextEditingController(text: viewModel.email);
    _genderController = TextEditingController(text: viewModel.gender);
    _ageController = TextEditingController(text: viewModel.age);
    _contactController = TextEditingController(text: viewModel.contactNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileScreenViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Personal Information")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _genderController,
              decoration: const InputDecoration(labelText: "Gender"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: "Age"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: "Contact Number"),
              keyboardType: TextInputType.phone,
            ),

            ElevatedButton(
              onPressed: () {
                viewModel.updatePersonalInfo(
                  _nameController.text,
                  _emailController.text,
                  _genderController.text,
                  _ageController.text,
                  _contactController.text,
                );
                Navigator.pop(context);
              },

              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
