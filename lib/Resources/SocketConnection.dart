import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/MyVibration.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';


class SocketConnection {



  Future<void> connect(context) async {
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
          debugPrint("Mailbox Number : $mailboxNumber is equal to $extension");
          final navigationProvider =  Provider.of<NavigationProvider>(context, listen: false);
          navigationProvider.setExtension(extension);
          navigationProvider.showFireAlarmWidget();
          myAudio.danger();
          vibrator.start();
        }else{
          debugPrint("Mailbox Number : $mailboxNumber is not equal to $extension");
        }
      });

      // Handle socket closure (optional)
      socket.done.then((_) {
        debugPrint("Connection closed.");
        // You might want to reconnect here
      });
    } on SocketException catch (e) {
      debugPrint("Connection error: $e");
    }
  }

}


