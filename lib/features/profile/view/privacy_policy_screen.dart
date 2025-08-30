import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Colors.white), // 👈 Title white
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white, // 👈 ensures default icons are white
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // 👈 back icon white
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ), // 👈 actions white
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('policies')
            .where('title', isEqualTo: 'Privacy Policy')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var doc = snapshot.data!.docs.first;
          var data = doc.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              data['content'] ?? 'Content not available',
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
