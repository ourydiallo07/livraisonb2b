import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class UserApp {
  String? id;
  String? firstName;
  String? lastName;
  String? phone;
  String? profileUrl;
  String? imageKey;
  int? bonus = 3;
  String? token;
  bool isAdmin;
  String? address;
  GeoPoint? location;
  double? personalDiscount;
  double? bonusThreshold;
  double? bonusRate;
  List<Map<String, dynamic>>? discountHistory;

  UserApp({
    this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.profileUrl,
    this.imageKey,
    this.bonus,
    this.token,
    this.isAdmin = false,
    this.address,
    this.location,
    this.personalDiscount,
    this.bonusThreshold,
    this.bonusRate,
    this.discountHistory,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'profileUrl': profileUrl,
      'imageKey': imageKey,
      'bonus': bonus,
      'token': token,
      'isAdmin': isAdmin,
      'address': address,
      'location': location,

      'personalDiscount': personalDiscount,
      'bonusThreshold': bonusThreshold,
      'bonusRate': bonusRate,
      'discountHistory': discountHistory,
    };
  }

  factory UserApp.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return UserApp.fromMap(data ?? {}, snapshot.id);
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  factory UserApp.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserApp(
      id: id,
      firstName: map['firstName'] != null ? map['firstName'] as String : null,
      lastName: map['lastName'] != null ? map['lastName'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      profileUrl:
          map['profileUrl'] != null ? map['profileUrl'] as String : null,
      imageKey: map['imageKey'] != null ? map['imageKey'] as String : null,
      bonus: map['bonus'] != null ? map['bonus'] as int : null,
      token: map['token'] as String?,
      isAdmin: map['isAdmin'] != null ? map['isAdmin'] as bool : false,
      address: map['address'] as String?,
      location: map['location'] as GeoPoint?,

      personalDiscount: map['personalDiscount']?.toDouble(),
      bonusThreshold: map['bonusThreshold']?.toDouble(),
      bonusRate: map['bonusRate']?.toDouble(),
      discountHistory:
          map['discountHistory'] != null
              ? List<Map<String, dynamic>>.from(map['discountHistory'])
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserApp.fromJson(DataSnapshot source) =>
      UserApp.fromMap(json.decode(json.encode(source.value)), source.key);

  factory UserApp.fromJsonString(String source) =>
      UserApp.fromMap(json.decode(source));

  void addDiscountRecord({
    required String type,
    required double value,
    required String adminId,
    String? notes,
  }) {
    discountHistory ??= [];
    discountHistory!.add({
      'type': type, // 'personal_discount', 'bonus_config', etc.
      'value': value,
      'adminId': adminId,
      'date': DateTime.now().toIso8601String(),
      if (notes != null) 'notes': notes,
    });
  }

  @override
  String toString() {
    return 'UserApp('
        'id: $id, '
        'firstName: $firstName, '
        'lastName: $lastName, '
        'phone: $phone, '
        'profileUrl: $profileUrl, '
        'imageKey: $imageKey, '
        'bonus: $bonus, '
        'token: $token, '
        'isAdmin: $isAdmin, '
        'address: $address, '
        'location: $location'
        'personalDiscount: $personalDiscount%, '
        'bonusThreshold: $bonusThreshold FCFA, '
        'bonusRate: $bonusRate%'
        ')';
  }

  UserApp copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileUrl,
    String? imageKey,
    int? bonus,
    String? token,
    bool? isAdmin,
    String? address,
    GeoPoint? location,
    double? personalDiscount,
    double? bonusThreshold,
    double? bonusRate,
    List<Map<String, dynamic>>? discountHistory,
  }) {
    return UserApp(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileUrl: profileUrl ?? this.profileUrl,
      imageKey: imageKey ?? this.imageKey,
      bonus: bonus ?? this.bonus,
      token: token ?? this.token,
      isAdmin: isAdmin ?? this.isAdmin,
      address: address ?? this.address,
      location: location ?? this.location,
      personalDiscount: personalDiscount ?? this.personalDiscount,
      bonusThreshold: bonusThreshold ?? this.bonusThreshold,
      bonusRate: bonusRate ?? this.bonusRate,
      discountHistory: discountHistory ?? this.discountHistory,
    );
  }
}
