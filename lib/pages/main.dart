import 'package:drivesense/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/logger_util.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging at the app level
  LoggerUtil.setupLogging();
  final logger = LoggerUtil.getLogger('Main');
  logger.info('Starting DriveSense application');

  await Firebase.initializeApp();
  logger.info('Firebase initialized');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
