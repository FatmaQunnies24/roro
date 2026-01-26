import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'view/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // معالجة الأخطاء عند تهيئة Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // في حالة فشل تهيئة Firebase، نستمر في تشغيل التطبيق
    debugPrint('خطأ في تهيئة Firebase: $e');
  }
  
  // معالجة الأخطاء العامة لمنع تعطل التطبيق
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('خطأ في Flutter: ${details.exception}');
  };
  
  // معالجة الأخطاء غير المعالجة
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('خطأ غير معالج: $error');
    return true;
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تقييم التوتر المرتبط بالألعاب الرقمية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginView(),
    );
  }
}
