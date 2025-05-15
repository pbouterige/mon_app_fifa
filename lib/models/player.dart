import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String id;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Player({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Player.fromMap(String id, Map<String, dynamic> map) {
    return Player(
      id: id,
      name: map['name'] as String,
      photoUrl: map['photoUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 