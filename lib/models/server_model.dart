import 'package:cloud_firestore/cloud_firestore.dart';

class Server {
  final String id;
  final String name;
  final String country;
  final String flag;
  final String ip;
  final bool isPro;
  final String? category;

  Server({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.ip,
    required this.isPro,
    this.category,
  });

  factory Server.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Server(
      id: doc.id,
      name: data['name'] ?? '',
      country: data['country'] ?? '',
      flag: data['flag'] ?? '',
      ip: data['ip'] ?? '',
      isPro: data['isPro'] ?? false,
      category: data['category'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'country': country,
      'flag': flag,
      'ip': ip,
      'isPro': isPro,
      'category': category,
    };
  }
}
