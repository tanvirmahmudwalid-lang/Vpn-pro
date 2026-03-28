import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize AdMob
  await MobileAds.instance.initialize();
  
  runApp(const BtafMeetApp());
}

class BtafMeetApp extends StatelessWidget {
  const BtafMeetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Btaf Meet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF005F8A),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005F8A),
          primary: const Color(0xFF005F8A),
          secondary: const Color(0xFF003D5B),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
