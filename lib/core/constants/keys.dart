import 'package:cloud_firestore/cloud_firestore.dart';

class CashfreeConfig {
  static Future<String> getAppId() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('settings')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return data['appId']?.toString() ?? '';
      }
      throw Exception('appId not found in Firestore settings');
    } catch (e) {
      print('❌ Error fetching appId from Firestore: $e');
      throw Exception('Failed to fetch appId: $e');
    }
  }

  static Future<String> getSecretKey() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('settings')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return data['secret key']?.toString() ?? '';
      }
      throw Exception('secret key not found in Firestore settings');
    } catch (e) {
      print('❌ Error fetching secret key from Firestore: $e');
      throw Exception('Failed to fetch secret key: $e');
    }
  }
}
