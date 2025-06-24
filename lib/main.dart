import 'package:diurecycle/Screen/splash.dart';
import 'package:firebase_core/firebase_core.dart';
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
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  
  OneSignal.initialize("8d3967fe-85a2-4355-81e9-1445123ff464");

  OneSignal.Notifications.requestPermission(true);
  OneSignal.Notifications.addClickListener((event) {
    print('Notification clicked: ${event.notification.additionalData}');
  });
  
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print('Notification received in foreground');
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