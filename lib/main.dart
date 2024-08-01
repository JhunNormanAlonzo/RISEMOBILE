
import 'dart:async';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/CoreController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/AwesomeChannel.dart';
import 'package:rise/Resources/AwesomeNotificationHandler.dart';
import 'package:rise/Resources/DatabaseConnection.dart';
import 'package:rise/Resources/MyHttpOverrides.dart';
import 'package:rise/Resources/Provider/CallProvider.dart';
import 'package:rise/Resources/Provider/JanusProvider.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:rise/Resources/Provider/SipRegistrationProvider.dart';
import 'package:rise/Views/Login.dart';
import 'package:rise/Views/QRPage.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  final appKey = await storageController.getData("appKey");

  await riseDatabase.database;



  List<NotificationChannel> channels = [awesomeChannel.fireChannel, awesomeChannel.callChannel, awesomeChannel.connectionChannel];
  AwesomeNotifications().initialize(null, channels, debug: true);

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: AwesomeNotificationHandler.onActionReceivedMethod,
    onNotificationCreatedMethod: AwesomeNotificationHandler.onNotificationCreatedMethod,
    onNotificationDisplayedMethod: AwesomeNotificationHandler.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: AwesomeNotificationHandler.onDismissActionReceivedMethod,
  );

  await coreController.requestPermission(Permission.storage);
  await coreController.requestPermission(Permission.camera);
  await coreController.requestPermission(Permission.audio);
  await coreController.requestPermission(Permission.storage);
  await coreController.requestPermission(Permission.microphone);
  await coreController.requestPermission(Permission.notification);



  storageController.storeData("janusConnection", "unregistered");

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => NavigationProvider()),
          ChangeNotifierProvider(create: (context) => CallProvider()),
          ChangeNotifierProvider(create: (context) => SipRegistrationProvider()),
          ChangeNotifierProvider(create: (context) => JanusProvider()),
        ],
        child: MyApp(isQRScanned: appKey?.isNotEmpty ?? false),
      )
  );
}



class MyApp extends StatelessWidget {
  final bool isQRScanned;

  const MyApp({super.key, required this.isQRScanned});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diavox Rise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: Pallete.backgroundColor
      ),
      home: isQRScanned ? const Login() : const QRPage(),
      // home: const TestingWidget()
    );
  }
}