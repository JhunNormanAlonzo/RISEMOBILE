import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:rise/Controllers/BackJanusController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/DatabaseConnection.dart';
import 'package:rise/Resources/MyAudio.dart';

class AwesomeNotificationHandler {
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    var backJanus = BackJanusController();
    final dynamic callStatus = await storageController.getData('callStatus');
    debugPrint("call status is : $callStatus");
    if(callStatus == "incoming"){
      IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipIncomingCallEvent');
    }


    if(receivedAction.buttonKeyPressed == 'ACCEPT'){
      debugPrint("Accept");
      myAudio.stop();
      await backJanus.accept();
      await riseDatabase.setActive("accepted");
      // FlutterBackgroundService().invoke('accept');
    }
  }

  // Optionally handle notification created event
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Handle notification created
  }

  // Optionally handle notification displayed event
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Handle notification displayed
  }

  // Optionally handle notification dismissed event
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    if(receivedAction.buttonKeyPressed == 'DECLINE'){
      var backJanus = BackJanusController();
      debugPrint("Declining");
      myAudio.stop();
      await backJanus.decline();
    }
  }
}
