
import 'dart:async';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/CoreController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/AwesomeChannel.dart';
import 'package:rise/Resources/AwesomeNotificationHandler.dart';
import 'package:rise/Resources/MyHttpOverrides.dart';
import 'package:rise/Resources/Provider/CallProvider.dart';
import 'package:rise/Resources/Provider/JanusProvider.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:rise/Resources/Provider/SipRegistrationProvider.dart';
import 'package:rise/Views/Login.dart';
import 'package:rise/Views/QRPage.dart';


//
//
// Future<void> downloadFile(String url, String filename) async {
//   // Request storage permission
//   final status = await Permission.storage.request();
//   if (status.isGranted) {
//     // Get external storage directory
//
//     final filePath = '${directory!.path}/Android/media/com.example.rise/alarms/$filename';
//
//     // Download the file
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       final file = File(filePath);
//       await file.writeAsBytes(response.bodyBytes);
//       print('File downloaded successfully!');
//     } else {
//       print('Download failed with status code: ${response.statusCode}');
//     }
//   } else {
//     print('Storage permission denied');
//   }
// }


//  putAlarmOnDeviceStorage () async{
//   Directory? appDocDir = await getExternalStorageDirectory();
//   String appDocPath = '${appDocDir?.path}/rise';
//   await Directory(appDocPath).create(recursive: true);
//   debugPrint(appDocPath);
//   File file1 = File('$appDocPath/ringing.mp3');
//   File file2 = File('$appDocPath/danger.mp3');
//   if (!await file1.exists()) {
//   ByteData data = await rootBundle.load('assets/sounds/ringing.mp3');
//   List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//   await file1.writeAsBytes(bytes);
//   }
//
//   if (!await file2.exists()) {
//   ByteData data = await rootBundle.load('assets/sounds/danger.mp3');
//   List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//   await file2.writeAsBytes(bytes);
//   }
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  final appKey = await storageController.getData("appKey");

  List<NotificationChannel> channels = [awesomeChannel.fireChannel, awesomeChannel.callChannel];
  AwesomeNotifications().initialize(null, channels, debug: true);

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: AwesomeNotificationHandler.onActionReceivedMethod,
    onNotificationCreatedMethod: AwesomeNotificationHandler.onNotificationCreatedMethod,
    onNotificationDisplayedMethod: AwesomeNotificationHandler.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: AwesomeNotificationHandler.onDismissActionReceivedMethod,
  );

  await coreController.requestPermission(Permission.camera);
  await coreController.requestPermission(Permission.audio);
  await coreController.requestPermission(Permission.storage);
  await coreController.requestPermission(Permission.microphone);
  await coreController.requestPermission(Permission.notification);
  await coreController.requestPermission(Permission.criticalAlerts);


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


// class TestingWidget extends StatefulWidget{
//   const TestingWidget({super.key});
//
//   @override
//   State<TestingWidget> createState() => _TestingWidgetState();
// }
//
// class _TestingWidgetState extends State<TestingWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             await testNotifications();
//           },
//           child: const Text("Test Notification"),
//         ),
//       ),
//     );
//   }
// }



//
// Future<void> testNotifications() async {
//   try {
//     // await AwesomeNotifications().createNotification(
//     //   content: NotificationContent(
//     //     id: 1,
//     //     channelKey: 'fire_channel', // For testing fire_channel
//     //     title: 'Fire Alert!',
//     //     body: 'Fire alarm has been triggered!',
//     //   ),
//     // );
//
//     AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: 2,
//         channelKey: 'call_channel',
//         title: "Call Notification",
//         body: 'Diavox Call Notification',
//         notificationLayout: NotificationLayout.BigText,
//       ),
//     );
//
//     // await AwesomeNotifications().createNotification(
//     //   content: NotificationContent(
//     //     id: 2,
//     //     channelKey: 'call_channel', // For testing call_channel
//     //     title: 'Incoming Call!',
//     //     body: 'You have an incoming call.',
//     //   ),
//     // );
//   } catch (e) {
//     print("Error creating notification: $e");
//   }
// }
