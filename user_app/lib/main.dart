import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app/dierb/app_shell.dart';

import 'commerce/cart_controller.dart';
import 'design/dierb_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => CartController(),
        child: MaterialApp(
          title: 'ديرب',
          debugShowCheckedModeBanner: false,
          theme: DierbTheme.light(),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
          home: const DierbAppShell(),
        ),
      );
}
