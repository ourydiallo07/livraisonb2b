import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livraisonb2b/models/app_user.dart';

class DiscountService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'USERS';

  static Future<void> applyPersonalDiscount({
    required String userId,
    required double discount,
    required String adminId,
  }) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'personalDiscount': discount,
      'discountHistory': FieldValue.arrayUnion([
        {
          'type': 'personal',
          'value': discount,
          'adminId': adminId,
          'date': DateTime.now().toIso8601String(), // Changé ici
        },
      ]),
      'updatedAt': FieldValue.serverTimestamp(), // Ajouté pour le suivi
    });
  }

  static Future<void> setupBonusProgram({
    required String userId,
    required double threshold,
    required double rate,
    required String adminId,
  }) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'bonusThreshold': threshold,
      'bonusRate': rate,
      'discountHistory': FieldValue.arrayUnion([
        {
          'type': 'bonus_config',
          'threshold': threshold,
          'rate': rate,
          'adminId': adminId,
          'date': DateTime.now().toIso8601String(), // Changé ici
        },
      ]),
      'updatedAt': FieldValue.serverTimestamp(), // Ajouté pour le suivi
    });
  }

  static double calculateAutomaticBonus(double cartTotal, UserApp user) {
    if (user.bonusThreshold == null ||
        user.bonusRate == null ||
        cartTotal < user.bonusThreshold!) {
      return 0.0;
    }
    return cartTotal * (user.bonusRate! / 100);
  }
}
