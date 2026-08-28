import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:seller_app/global/global.dart';
import 'package:seller_app/splashScreen/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dierbFirebase = FirebaseOptions(
  apiKey: 'AIzaSyBVUGFEPhyNrFwkMjEuV4PGk7EEQS_CQ5I',
  appId: '1:365123606367:android:2067df0428046493b8c8ea',
  messagingSenderId: '365123606367',
  projectId: 'dierb-29548',
  storageBucket: 'dierb-29548.firebasestorage.app',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  await Firebase.initializeApp(options: _dierbFirebase);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ديرب للتجار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166534)),
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.white),
      ),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const MySplashScreen(),
    );
  }
}


