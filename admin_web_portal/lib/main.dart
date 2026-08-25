import 'package:admin_web_portal/mainScreens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'authentication/login.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة ديرب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166534)), scaffoldBackgroundColor: const Color(0xFFF7F8F5)),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: FirebaseAuth.instance.currentUser == null ? const LoginScreen() : const _AdminGate(),
    );
  }
}

class _AdminGate extends StatelessWidget {
  const _AdminGate();
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('admins').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.data?.exists == true) return const HomeScreen();
        return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.admin_panel_settings_outlined, size: 64), const SizedBox(height: 12), const Text('هذا الحساب غير مصرح له بدخول الإدارة'), TextButton(onPressed: () async { await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); }, child: const Text('تسجيل الخروج'))])));
      },
    );
  }
}
