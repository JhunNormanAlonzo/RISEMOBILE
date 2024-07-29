
import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BackgroundWebsocket {
  BackgroundWebsocket._internal();
  static final BackgroundWebsocket _instance = BackgroundWebsocket._internal();
  factory BackgroundWebsocket() {
    return _instance;
  }


  WebSocketChannel? _channel;




  Future<void> listen() async {
    final androidHost = await api.getAndroidHost();
    debugPrint("Websocket Connecting...");
    _channel = IOWebSocketChannel.connect(Uri.parse('wss://$androidHost:6002/app/8edc987616d1eaa476e1?protocol=7&client=js&version=4.4.0&flash=false'));
    debugPrint("Websocket Connected...");
    debugPrint("Websocket Subscribing...");
    _channel!.sink.add(json.encode({
      "event": "pusher:subscribe",
      "data": {
        "channel": "mobileChannel"
      }
    }));

    _channel!.stream.listen((data) async{
      final lifecycle = await AwesomeNotifications().getAppLifeCycle();
      final mailboxNumber = await storageController.getData("mailboxNumber");
      Map<String, dynamic> jsonMap = jsonDecode(data);

      try{
        String dataString = jsonMap['data'];
        debugPrint("DataString: ${jsonMap['channel']}");
        if(jsonMap['channel'] == 'mobileChannel'){
          Map<String, dynamic> dataMap = jsonDecode(dataString);
          debugPrint('Origin: ${dataMap['origin']}');
          final extension = dataMap['extension'];
          final alarmType = dataMap['alarm_type'];
          final origin = dataMap['origin'];
          debugPrint("Message Received : $dataMap");

          debugPrint("Mailbox Number : $mailboxNumber");
          if(mailboxNumber == extension){
            debugPrint("Mailbox Number : $mailboxNumber is equal to $extension");
            if(lifecycle == NotificationLifeCycle.Background){
              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                    id: 1,
                    channelKey: 'fire_channel',
                    title: "Fire Notification",
                    body: 'Fire alarm on $extension!',
                    autoDismissible: false,
                    duration: const Duration(seconds: 20)
                ),
              );
            }else if(lifecycle == NotificationLifeCycle.Foreground){
              IsolateNameServer.lookupPortByName('mainIsolate')?.send('FireAlarmEvent-$extension');
            }


          }else{
            debugPrint("Mailbox Number : $mailboxNumber is not equal to $extension");
          }
        }else{
          debugPrint("Received data: $jsonMap");
        }
      }catch(e){
        debugPrint("Websocket Initialization");
      }
    });

  }

  disconnect(){
    channel!.sink.close();
  }



  Stream get stream => _channel!.stream;
  WebSocketChannel? get channel => _channel;
}


