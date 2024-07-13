import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:rise/Controllers/StorageController.dart';

class AwesomeNotificationHandler {
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final dynamic callStatus = await storageController.getData('callStatus');
    debugPrint("call status is : $callStatus");
    if(callStatus == "incoming"){
      IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipIncomingCallEvent');
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
    // Handle notification dismissed
  }
}
