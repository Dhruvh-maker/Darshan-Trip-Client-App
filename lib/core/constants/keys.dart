import 'package:cloud_firestore/cloud_firestore.dart';

class CashfreeConfig {
  static Future<String> getAppId() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('landingPage')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['appId']?.toString() ?? '';
      }
      throw Exception('appId not found in Firestore settings/landingPage');
    } catch (e) {
      print('❌ Error fetching appId from Firestore: $e');
      throw Exception('Failed to fetch appId: $e');
    }
  }

  static Future<String> getSecretKey() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('landingPage')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['secret key']?.toString() ?? '';
      }
      throw Exception('secret key not found in Firestore settings/landingPage');
    } catch (e) {
      print('❌ Error fetching secret key from Firestore: $e');
      throw Exception('Failed to fetch secret key: $e');
    }
  }
}
