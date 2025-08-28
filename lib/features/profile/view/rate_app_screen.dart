import 'package:flutter/material.dart';

class RateAppScreen extends StatelessWidget {
  const RateAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rate Our App"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white, // Set text and icon color to white
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/celebrate.png', height: 150, width: 150),
            const SizedBox(height: 20),
            const Text(
              'We\'d love to hear from you!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) =>
                    const Icon(Icons.star, color: Colors.amber, size: 30),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your feedback helps us improve and provide better services. Please take a moment to rate our app!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add your rate app logic here
              },
              child: const Text('Rate Now'),
            ),
          ],
        ),
      ),
    );
  }
}
