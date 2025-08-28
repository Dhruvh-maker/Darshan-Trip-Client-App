import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darshan_trip/features/profile/viewmodel/wallet_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  String? appLink;
  bool isLoadingLink = true;

  @override
  void initState() {
    super.initState();
    _fetchAppLink();
  }

  Future<void> _fetchAppLink() async {
    try {
      // 👇 Fetch the first document in "settings" collection
      final snapshot = await FirebaseFirestore.instance
          .collection('settings')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          appLink = snapshot.docs.first['applink'] as String?;
          isLoadingLink = false;
        });
      } else {
        setState(() {
          appLink = null;
          isLoadingLink = false;
        });
      }
    } catch (e) {
      setState(() {
        appLink = null;
        isLoadingLink = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final referralCode = walletVM.myReferralCode ?? 'LOADING...';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Refer & Earn"),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/celebrate.png', height: 150, width: 150),
            const SizedBox(height: 20),
            const Text(
              "Invite Friends, Earn Rewards!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Share your unique referral code with friends. When they sign up, you both get bonus points in your wallet!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            const Text(
              "YOUR REFERRAL CODE",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                if (referralCode != 'LOADING...') {
                  Clipboard.setData(ClipboardData(text: referralCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Referral code copied to clipboard!'),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      referralCode,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.copy, color: Colors.orange, size: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // SHARE BUTTON
            ElevatedButton.icon(
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                "SHARE NOW",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                if (referralCode != 'LOADING...' && !isLoadingLink) {
                  final shareText =
                      "Hey! Join me on Darshan Trip and get rewards 🎉\n\n"
                      "Use my referral code: $referralCode\n\n"
                      "Download the app here: ${appLink ?? 'App link coming soon!'}";
                  Share.share(shareText);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
