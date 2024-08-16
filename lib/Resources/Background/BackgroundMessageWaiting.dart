
import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/BackJanusController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/ForegroundService.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BackgroundMessageWaiting {
  BackgroundMessageWaiting._internal();
  static final BackgroundMessageWaiting _instance = BackgroundMessageWaiting._internal();
  factory BackgroundMessageWaiting() {
    return _instance;
  }


  WebSocketChannel? _channel;




  Future<void> listen() async {
    final mailboxNumber = await storageController.getData("mailboxNumber");
    final androidHost = await api.getAndroidHost();
    final channelName = "mobileGlobalChannel-$mailboxNumber";
    debugPrint("Websocket Connecting...");
    _channel = IOWebSocketChannel.connect(Uri.parse('wss://$androidHost:6002/app/8edc987616d1eaa476e1?protocol=7&client=js&version=4.4.0&flash=false'));
    debugPrint("Websocket Message Waiting Connected in channel $channelName...");
    debugPrint("Websocket Message Waiting Subscribing...");
    _channel!.sink.add(json.encode({
      "event": "pusher:subscribe",
      "data": {
        "channel": channelName
      }
    }));

    _channel!.stream.listen((data) async{
      Map<String, dynamic> jsonMap = jsonDecode(data);

      try{
        String dataString = jsonMap['data'];
        debugPrint("DataString: ${jsonMap['channel']}");
        Map<String, dynamic> dataMap = jsonDecode(dataString);
        final event = dataMap['event'];
        final extension = dataMap['extension'];
        if(event == "message-waiting"){
          if(mailboxNumber == extension){
            IsolateNameServer.lookupPortByName('mainIsolate')?.send('MessageWaitingEvent-$extension');
          }
        }
        debugPrint("data : $dataMap");
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


