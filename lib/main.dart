// lib/main.dart

import 'dart:convert';
import 'package:drivesense/screens/drivers_request_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/logger_util.dart';
import 'screens/splash_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/company_requests_page.dart';

// Route observer for navigation tracking
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
// Navigator key for handling navigation outside widget context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Local notifications plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Top-level background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LoggerUtil.getLogger('Main').info('Background message ID: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  LoggerUtil.setupLogging();
  final mainLogger = LoggerUtil.getLogger('Main');
  mainLogger.info('Starting DriveSense application');

  // Initialize Firebase
  await Firebase.initializeApp();
  mainLogger.info('Firebase initialized');

  // Activate App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidInitSettings),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      mainLogger.info('Notification tapped with payload: $payload');
      // _handleNotificationNavigation(payload);
    },
  );

  runApp(const MyApp());
}

// /// Parses the notification payload and navigates to the appropriate screen
// void _handleNotificationNavigation(String? payload) {
//   if (payload == null) return;
//   final logger = LoggerUtil.getLogger('Main');
//   try {
//     final data = jsonDecode(payload) as Map<String, dynamic>;
//     final type = data['type'] as String;
//     final refId = data['refId'] as String;
//
//     switch (type) {
//       case 'joinRequest':
//       // Company views join requests
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(
//             builder: (_) => CompanyRequestsPage(companyId: '',),
//           ),
//         );
//         break;
//       case 'hireRequest':
//       // Driver views hire requests
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(
//             builder: (_) => DriverRequestsPage(),
//           ),
//         );
//         break;
//       case 'chat':
//         final companyId = data['companyId'] as String;
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(
//             builder: (_) => ChatScreen(
//               companyId: companyId,
//               peerId: refId,
//             ),
//           ),
//         );
//         break;
//       default:
//         logger.info('Unknown notification type: $type');
//     }
//   } catch (e, st) {
//     LoggerUtil.getLogger('Main').severe('Navigation error', e, st);
//   }
// }

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final fcm = FirebaseMessaging.instance;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Request notification permissions (iOS)
    await fcm.requestPermission();

    // Obtain FCM token
    final token = await fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final notif = msg.notification;
      if (notif != null) {
        final data = {
          'type': msg.data['type'],
          'refId': msg.data['refId'],
          if (msg.data['companyId'] != null) 'companyId': msg.data['companyId'],
        };
        flutterLocalNotificationsPlugin.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'driveSense',
              'DriveSense Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(data),
        );
      }
    });

    // Handle notification taps when app is in background or quit
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      final data = {
        'type': msg.data['type'],
        'refId': msg.data['refId'],
        if (msg.data['companyId'] != null) 'companyId': msg.data['companyId'],
      };
      final payload = jsonEncode(data);
      LoggerUtil.getLogger('Main').info('Notification opened with payload: $payload');
      // _handleNotificationNavigation(payload);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      title: 'DriveSense',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
