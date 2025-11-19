import 'package:diurecycle/Screen/splash.dart';
import 'package:diurecycle/config/env.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  await initializeOneSignal();
  
  runApp(MyApp());
}

//OneSignal
Future<void> initializeOneSignal() async {
  // Only enable verbose logging in debug mode
  if (kDebugMode) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  } else {
    OneSignal.Debug.setLogLevel(OSLogLevel.none);
  }
  
  OneSignal.initialize(Env.oneSignalAppId);

  OneSignal.Notifications.requestPermission(true);
  OneSignal.Notifications.addClickListener((event) {
    if (kDebugMode) {
      print('Notification clicked: ${event.notification.additionalData}');
    }
  });
  
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    if (kDebugMode) {
      print('Notification received in foreground');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DIU Recycle',
      home: SplashScreen(),
    );
  }
}