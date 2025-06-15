// ignore_for_file: public_member_api_docs, sort_constructors_first
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

  UserApp({
    this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.profileUrl,
    this.imageKey,
    this.bonus,
    this.token,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'imageKey': imageKey,
      'bonus': bonus,
      'token': token,
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

  factory UserApp.fromMap(Map<String, dynamic> map, String? id) {
    return UserApp(
      id: id,
      firstName: map['firstName'] != null ? map['firstName'] as String : null,
      lastName: map['lastName'] != null ? map['lastName'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      imageKey: map['imageKey'] != null ? map['imageKey'] as String : null,
      bonus: map['bonus'] != null ? map['bonus'] as int : null,
      token: map['token'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserApp.fromJson(DataSnapshot source) =>
      UserApp.fromMap(json.decode(json.encode(source)), source.key);

  @override
  String toString() {
    return 'AppUser(firstName: $firstName, lastName: $lastName, phone: $phone, profileUrl: $profileUrl, imageKey: $imageKey,bonus:$bonus)';
  }
}
