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

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<ProfileScreenViewModel>(
      context,
      listen: false,
    );
    _nameController = TextEditingController(text: viewModel.userName);
    _emailController = TextEditingController(text: viewModel.email);
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
            ElevatedButton(
              onPressed: () {
                viewModel.updatePersonalInfo(
                  _nameController.text,
                  _emailController.text,
                );
                Navigator.pop(context); // Go back to Profile Screen
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
