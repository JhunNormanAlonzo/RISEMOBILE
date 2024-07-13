import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/ForegroundService.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/MyVibration.dart';
import 'package:rise/Resources/NativeRingtone.dart';


class BackgroundSocket {


  Future<void> connect() async {
    final serverHost = await api.getAndroidHost();
    const int serverPort = 6003;


    final mailboxNumber = await storageController.getData("mailboxNumber");
    try {
      final socket = await Socket.connect(InternetAddress(serverHost!), serverPort);
      debugPrint("Connected to server: $serverHost:$serverPort");
      socket.listen((data) {
        final jsonData = utf8.decode(data);
        final dataMap = jsonDecode(jsonData) as Map<String, dynamic>;
        final extension = dataMap['extension'];
        final alarmType = dataMap['alarm_type'];
        final origin = dataMap['origin'];
        debugPrint("Extension : $extension");
        debugPrint("Alarm Type :  $alarmType");
        debugPrint("Origin : $origin");
        debugPrint("Message Received : $dataMap");
        debugPrint("Mailbox Number : $mailboxNumber");

        if(mailboxNumber == extension){
          vibrator.start();
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: 1,
              channelKey: 'fire_channel',
              title: "Fire Notification",
              body: 'Fire alarm on $extension!',
            ),
          );
          debugPrint("Mailbox Number : $mailboxNumber is equal to $extension");
        }else{
          debugPrint("Mailbox Number : $mailboxNumber is not equal to $extension");
        }
      });

      socket.done.then((_) {
        debugPrint("Connection closed.");
      });
    } on SocketException catch (e) {
      debugPrint("Connection error: $e");
    }
  }
}