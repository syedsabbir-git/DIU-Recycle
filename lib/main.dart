import 'package:diurecycle/Screen/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize OneSignal
  await initializeOneSignal();
  
  runApp(MyApp());
}

// Function to initialize OneSignal
Future<void> initializeOneSignal() async {
  // Replace with your OneSignal App ID
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  
  OneSignal.initialize("8d3967fe-85a2-4355-81e9-1445123ff464");
  
  // Request permission for notifications
  OneSignal.Notifications.requestPermission(true);
  
  // Set notification handlers
  OneSignal.Notifications.addClickListener((event) {
    print('Notification clicked: ${event.notification.additionalData}');
    // You can navigate to specific screens based on notification data here
  });
  
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print('Notification received in foreground');
    // You can either display the notification or modify it before showing
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