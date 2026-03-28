import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isPro;
  final bool isPremium;
  final int sessionTimeRemaining;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.isPro,
    required this.isPremium,
    required this.sessionTimeRemaining,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      isPro: data['isPro'] ?? false,
      isPremium: data['isPremium'] ?? false,
      sessionTimeRemaining: data['sessionTimeRemaining'] ?? 0,
    );
  }
}
