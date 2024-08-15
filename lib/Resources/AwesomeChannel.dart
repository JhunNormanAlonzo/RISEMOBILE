

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:rise/Resources/Pallete.dart';

class AwesomeChannel {

  NotificationChannel fireChannel = NotificationChannel(
    channelKey: 'fire_channel',
    channelName: 'Fire Notification',
    channelDescription: 'Fire alarm triggered!',
    importance: NotificationImportance.Max,
    playSound: true,
    enableVibration: true,
    soundSource: 'resource://raw/res_danger',
    defaultColor: Pallete.gradient3,
    ledColor: Pallete.gradient4,
    criticalAlerts: true,
    enableLights: true,
    channelShowBadge: true,
  );


  NotificationChannel callChannel = NotificationChannel(
    channelKey: 'call_channel',
    channelName: 'Call Notifications',
    channelDescription: 'Notification channel for incoming calls',
    importance: NotificationImportance.Max,
    playSound: true,
    enableVibration: true,
    soundSource: 'resource://raw/res_ringing',
    defaultColor: Pallete.gradient3,
    ledColor: Pallete.gradient4,
    criticalAlerts: true,
    enableLights: true,
    locked: true,
    defaultPrivacy: NotificationPrivacy.Public,
    channelShowBadge: true,
  );




  NotificationChannel connectionChannel = NotificationChannel(
    channelKey: 'connection_channel',
    channelName: 'Connecting to Server',
    channelDescription: 'Connecting to server',
    importance: NotificationImportance.Max,
    playSound: true,
    enableVibration: true,
    defaultColor: Pallete.gradient3,
    ledColor: Pallete.gradient4,
    criticalAlerts: true,
    enableLights: true,
    channelShowBadge: true,
  );


}

final awesomeChannel = AwesomeChannel();