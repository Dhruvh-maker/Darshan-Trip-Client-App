import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Terms and Conditions",
          style: TextStyle(color: Colors.white), // 👈 Title White
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white, // 👈 Ensures back icon is white
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // 👈 Back button white
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ), // 👈 Any actions white
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('policies')
            .where('title', isEqualTo: 'Terms and conditions')
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
