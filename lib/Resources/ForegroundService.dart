
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/BackJanusController.dart';
import 'package:rise/Resources/AwesomeChannel.dart';
import 'package:rise/Resources/AwesomeNotificationHandler.dart';
import 'package:rise/Resources/Background/BackgroundMessageWaiting.dart';
import 'package:rise/Resources/Background/BackgroundWebsocket.dart';
import 'package:rise/Resources/Janus/janus_client.dart';
import 'package:rise/Resources/MyHttpOverrides.dart';
import 'package:rise/Resources/MyVibration.dart';
import 'package:rise/Resources/Provider/JanusProvider.dart';

SendPort? sendPortToMainFrame;
Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
    ),
  );

  service.startService();
}


@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  HttpOverrides.global = MyHttpOverrides();
  var backWebsocket = BackgroundWebsocket();
  var messageWaitingSocket = BackgroundMessageWaiting();
  if (service is AndroidServiceInstance) {

    var backJanus = BackJanusController();

    List<NotificationChannel> channels = [awesomeChannel.fireChannel, awesomeChannel.callChannel, awesomeChannel.connectionChannel];
    AwesomeNotifications().initialize(null, channels, debug: true);

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: AwesomeNotificationHandler.onActionReceivedMethod,
      onNotificationCreatedMethod: AwesomeNotificationHandler.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: AwesomeNotificationHandler.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: AwesomeNotificationHandler.onDismissActionReceivedMethod,
    );


    final Connectivity connectivity = Connectivity();

    connectivity.onConnectivityChanged.listen((event) async {
      debugPrint("connectivity event : ${event.toString()}");

      if (event.toString() == "[ConnectivityResult.wifi]") {
        await api.syncSipRegistration();
        final registrationStatus = await api.checkSipRegistration();
        debugPrint("registration status wifi : $registrationStatus");

        debugPrint("connectivity is wifi");

        backWebsocket.listen();
        messageWaitingSocket.listen();




        await backJanus.initJanusClient();

        if(registrationStatus == "registered"){
          await backJanus.unRegister();
        }
        Future.delayed(const Duration(seconds: 5), () async{
          await backJanus.autoRegister();
        });
      } else {
        AwesomeNotifications().cancel(3);
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: 3,
              channelKey: 'connection_channel',
              title: "SIP Notification",
              body: 'Connecting to server',
              duration: const Duration(seconds: 10)
          ),
        );
        Future.delayed(const Duration(seconds: 5), () async{
          IsolateNameServer.lookupPortByName('mainIsolate')?.send("SipUnRegisteredEvent");
        });

        debugPrint("Not connected to WiFi");
      }
    });




    service.on('websocketDisconnect').listen((event) {
      backWebsocket.disconnect();
    });



    service.on('disconnectJanus').listen((event) {
      backJanus.disconnectJanusClient();
    });



    service.on('testerMethod').listen((event) {

    });


    service.on('initializeWebRTCStack').listen((event) async{
      await backJanus.sip?.initializeWebRTCStack();
    });


    service.on('handleRemoteJsep').listen((event) async{
      RTCSessionDescription? remoteOffer = event?['remoteOffer'];
      await backJanus.sip?.handleRemoteJsep(remoteOffer);
    });





    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('disposeJanusClient').listen((event) {
      print("disconnecting");
    });

    service.on('disposeMediaStream').listen((event) {
      print("disconnecting");
    });

    service.on('reconnect').listen((event) {
      print("reconnecting");
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('stopVibration').listen((event) {
      vibrator.stop();
    });
    service.on('startVibration').listen((event) {
      vibrator.start();
    });

    service.on('enableSpeakerMode').listen((event) {
      final bool mode = event?['mode'];
      debugPrint("Setting speaker mode to $mode");
      backJanus.enableSpeakerMode(mode);
    });




    service.on('stopAllTracks').listen((event) {
      debugPrint("Stopping all tracks");
      backJanus.stopTracks();
    });



    service.on('registerUser').listen((event) async {
      debugPrint("Registering User");
      final androidHost = event?['androidHost'];
      final username = event?['username'];
      final password = event?['password'];
      debugPrint("android host : $androidHost");
      debugPrint("android host : $username");
      debugPrint("android host : $password");
      await backJanus.registerUser(androidHost!, username, password);
    });

    service.on('autoRegister').listen((event) async {

      debugPrint("Auto Registering User");
      await backJanus.autoRegister();
    });



    service.on('hangup').listen((event) {
      debugPrint("****************************Sending HANGUP using background****************************************");
      backJanus.hangup();
    });

    service.on('decline').listen((event) {
      debugPrint("****************************Sending DECLINE using background****************************************");
      backJanus.decline();
    });

    service.on('accept').listen((event) async {
      debugPrint("****************************Sending ACCEPT using background****************************************");
      await backJanus.accept();
      await backJanus.enableSpeakerMode(false);
    });

    service.on('muteUnmute').listen((event) async {
      debugPrint("****************************Sending MUTE UNMUTE using background****************************************");

      final flag = event?['flag'];
      final isMuted = event?['isMuted'];

      await backJanus.muteUnmute(flag, isMuted);
    });

    service.on('dtmf').listen((event) {
      debugPrint("****************************Sending DTMF using background****************************************");
      final inputNumber = event?['inputNumber'];
      backJanus.sendDtmf(inputNumber);
    });


    service.on('unRegister').listen((event) {
      debugPrint("****************************Sending UNREGISTER using background****************************************");
      backJanus.unRegister();
    });




    service.on('makeCall').listen((event) async{
      debugPrint("****************************Sending MakeCall using background****************************************");
      final androidHost = event?['androidHost'];
      final inputNumber = event?['inputNumber'];
      backJanus.makeCall(inputNumber, androidHost);
    });

    // List<NotificationChannel> channels = [awesomeChannel.fireChannel, awesomeChannel.callChannel];
    // AwesomeNotifications().initialize(null, channels, debug: true);
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });


  // AwesomeNotifications().createNotification(
  //   content: NotificationContent(
  //     id: 1,
  //     channelKey: 'call_channel',
  //     title: "Call Notification",
  //     body: 'Call alarm!',
  //   ),
  // );
  //



  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      service.setForegroundNotificationInfo(
          title: "Diavox Rise",
          content: "Background service is running..."
      );
      debugPrint("Background service is running...");
    }
  }

}



void setSendPortFromForeground(SendPort? port) {
  sendPortToMainFrame = port; // Store the received SendPort
}