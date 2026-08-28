import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rider_app/splashScreen/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design/dierb_theme.dart';
import 'global/global.dart';

const _dierbFirebase = FirebaseOptions(
  apiKey: 'AIzaSyBVUGFEPhyNrFwkMjEuV4PGk7EEQS_CQ5I',
  appId: '1:365123606367:android:e7077cf997d916cab8c8ea',
  messagingSenderId: '365123606367',
  projectId: 'dierb-29548',
  storageBucket: 'dierb-29548.firebasestorage.app',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  await Firebase.initializeApp(options: _dierbFirebase);
  firebaseAuth = FirebaseAuth.instance;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ديرب للمندوبين',
      debugShowCheckedModeBanner: false,
      theme: DierbTheme.light(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const MySplashScreen(),
    );
  }
}
