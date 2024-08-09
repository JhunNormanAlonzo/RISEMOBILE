import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:audio_session/audio_session.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lecle_volume_flutter/lecle_volume_flutter.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/DatabaseConnection.dart';
import 'package:rise/Resources/Janus/janus_client.dart';
import 'package:rise/Resources/Pallete.dart';


class BackJanusController{
  BackJanusController._internal();
  static final BackJanusController _instance = BackJanusController._internal();
  factory BackJanusController() {
    return _instance;
  }




  JanusSipPlugin? sip;
  RTCSessionDescription? rtc;
  MediaStream? mediaStream;
  final RTCVideoRenderer _remoteVideoRenderer = RTCVideoRenderer();
  late JanusClient j;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  RTCTrackEvent? rtcTrackEvent;
  RTCPeerConnection? pc;
  RemoteTrack? remoteTrack;
  JanusPlugin? jp;

  final StreamController<String> _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageStreamController.stream;

  void sendMessageToFrontend(String message) {
    _messageStreamController.add(message);
  }

  void dispose() {
    _messageStreamController.close();
  }

  void testerMethod() async{
    final devices =  await sip?.getAudioInputDevices();
    devices?.forEach((element) {
      print(element.kind);
    });

  }


  localStreamInitializer() async{
     MediaStream? temp = await sip?.initializeMediaDevices(mediaConstraints: {'audio': true, 'video': false});
     mediaStream = temp;
  }



  closePeerConnection() async{
    sip?.webRTCHandle?.peerConnection?.close();
    sip?.webRTCHandle?.peerConnection = null;
  }

  Future<void> initJanusClient() async {
    await disconnectJanusClient();
    debugPrint("****************************initializing janus client...******************************");
    final gateway = await storageController.getData("gateway");
    if (sip == null) {
      debugPrint("initializing the init janus client");
      final ws = WebSocketJanusTransport(url: gateway);
      debugPrint("getting janus status start");
      await ws.getInfo();
      debugPrint("getting janus status end" );

      final j = JanusClient(transport: ws, iceServers: null, isUnifiedPlan: true);
      session = await j.createSession();
      print("session object : $session");
      sip = await session!.attach<JanusSipPlugin>();
      sip?.typedMessages?.listen((even) async {
        Object data = even.event.plugindata?.data;
        print("EVENT TRIGGERED : $data");
        if (data is SipIncomingCallEvent) {
          debugPrint("--------------------------------------INCOMING CALL ALERT EVENT----------------------------------------------");
          String callerString = data.result?.username as String;
          RegExp regex = RegExp(r":(.+)@");
          Match match = regex.firstMatch(callerString) as Match;
          String number = match.group(1)!;
          await sip?.initializeWebRTCStack();
          rtc = even.jsep;
          IsolateNameServer.lookupPortByName('mainIsolate')?.send("SipIncomingCallEvent");
          await storageController.storeData("caller", number);
          await riseDatabase.insertHistory(number, "incoming");
          storageController.storeData("callStatus", "incoming");
          await riseDatabase.setActive("incoming");
          final lifecycle = await AwesomeNotifications().getAppLifeCycle();


          debugPrint("Executing delayed WebRTC initialization and jsep handling");

          // rtc = even.jsep;
          debugPrint("sending set ready");






          if(lifecycle == NotificationLifeCycle.Background){
            final caller = await storageController.getData("caller");
            AwesomeNotifications().createNotification(
                content: NotificationContent(
                    id: 2,
                    channelKey: 'call_channel',
                    title: "Call Notification",
                    body: 'Incoming call $caller!',
                    autoDismissible: false,
                    duration: const Duration(seconds: 20)
                ),
                actionButtons: [
                  NotificationActionButton(key: 'ACCEPT', label: 'Accept', actionType: ActionType.Default),
                  NotificationActionButton(key: 'DECLINE', label: 'Decline', actionType: ActionType.DismissAction),
                ]
            );
          }

          debugPrint("--------------------------------------INCOMING CALL ALERT DONE----------------------------------------------");
        }
        if (data is SipAcceptedEvent) {
          debugPrint("--------------------------------------INCOMING CALL ACCEPTED EVENT RECEIVED----------------------------------------------");
          RTCSessionDescription? remoteOffer = even.jsep;
          await sip?.handleRemoteJsep(remoteOffer);
          await riseDatabase.setAccepted(1);
          IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipAcceptedEvent');
          debugPrint("--------------------------------------INCOMING CALL ACCEPTED EVENT DONE----------------------------------------------");
          // navigationProvider.showOnCallWidget();
        }

        if(data is SipUnRegisteredEvent){
          debugPrint("--------------------------------------UN-REGISTERED EVENT RECEIVED----------------------------------------------");
          IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipUnRegisteredEvent');
          debugPrint("--------------------------------------UN-REGISTERED EVENT DONE----------------------------------------------");
        }

        if (data is SipHangupEvent) {
          // sip?.dispose();
          // session.dispose();
          await sip?.webRTCHandle?.peerConnection?.close();
          await stopAllTracksAndDispose(mediaStream);
          riseDatabase.setAccepted(0);
          debugPrint("--------------------------------------HANGUP EVENT RECEIVED----------------------------------------------");
          storageController.storeData("callStatus", "empty");
          IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipHangupEvent');
          AwesomeNotifications().cancel(2);
          debugPrint("--------------------------------------HANGUP EVENT DONE----------------------------------------------");
          // navigationProvider.hideOnCallWidget();
        }
        if (data is SipRegisteredEvent) {
          debugPrint("--------------------------------------REGISTERED EVENT RECEIVED----------------------------------------------");
          IsolateNameServer.lookupPortByName('mainIsolate')?.send(
              'SipRegisteredEvent');
          storageController.storeData("janusConnection", "registered");
          debugPrint("--------------------------------------REGISTERED EVENT DONE----------------------------------------------");
        }
        if (data is SipCallingEvent) {
          debugPrint("--------------------------------------Setting callStatus to Outgoing----------------------------------------------");
          storageController.storeData("callStatus", "outgoing");
          debugPrint("--------------------------------------SipCallingEvent EVENT RECEIVED----------------------------------------------");
        }
        if (data is SipMissedCallEvent) {
          debugPrint("--------------------------------------Setting callStatus to empty----------------------------------------------");
          storageController.storeData("callStatus", "empty");
          debugPrint("--------------------------------------SipMissedCallEvent EVENT RECEIVED----------------------------------------------");
        }
        if (data is SipProceedingEvent) {
          await sip?.handleRemoteJsep(even.jsep);
          debugPrint("--------------------------------------SipProceedingEvent EVENT RECEIVED----------------------------------------------");
          debugPrint("--------------------------------------Proceeding | Ringing----------------------------------------------");
          debugPrint("--------------------------------------SipProceedingEvent EVENT RECEIVED DONE----------------------------------------------");
        }
        if (data is SipProgressEvent) {
          await sip?.handleRemoteJsep(even.jsep);
          debugPrint("--------------------------------------SipProgressEvent EVENT RECEIVED----------------------------------------------");
        }
        if (data is SipRingingEvent) {
          await sip?.handleRemoteJsep(even.jsep);
          debugPrint("--------------------------------------SipRingingEvent EVENT RECEIVED----------------------------------------------");
          debugPrint("--------------------------------------Ringing----------------------------------------------");
          debugPrint("--------------------------------------SipRingingEvent EVENT RECEIVED DONE----------------------------------------------");
        }
        if (data is SipAcceptedEventResult) {
          await sip?.handleRemoteJsep(even.jsep);
          debugPrint("--------------------------------------SipAcceptedEventResult EVENT RECEIVED----------------------------------------------");
        }
      }, onError: (error) async {
        if (error is JanusError) {
          IsolateNameServer.lookupPortByName('mainIsolate')?.send('$error');
          // toast.error(_context!, error.error);
        }
      });

    }
  }


  Future<void> disconnectJanusClient() async {
    try{
      if (session != null) {

        sip = null;
        debugPrint("Janus SIP plugin detached.");

        session.dispose();
        debugPrint("Janus session destroyed.");
      }
    }catch(e){
      print(e);
    }

  }


  hangup() async{
    debugPrint("**********************************Hangup Call*************************************");
    await sip?.webRTCHandle?.peerConnection?.close();
    // sip?.dispose();
    // session.dispose();
    await sip?.hangup();
  }

  sendDtmf(number){
    sendMessageToFrontend("message to frontend");
    Map<String, dynamic> dtmf = {"tones": "$number"};
    sip?.sendDtmf(dtmf);
  }

  Future<void> registerUser(String ip, String username, String password) async {
    debugPrint("Triggering registration...");
    await sip?.register("sip:$username@$ip",
        forceUdp: true,
        rfc2543Cancel: true,
        proxy: "sip:$ip",
        secret: password);
    debugPrint("Registration triggered...");
  }


  Future<void> autoRegister() async{
    debugPrint("triggering auto registration");
    try{
      final mailbox = await storageController.getData("mailboxNumber");
      final password = await storageController.getData("password");
      final androidHost = await api.getAndroidHost();
      debugPrint("mailbox is : $mailbox");
      debugPrint("password is : $password");
      debugPrint("androidHost is : $androidHost");
      debugPrint("Triggering registration...");
      await sip?.register("sip:$mailbox@$androidHost",
          forceUdp: true,
          rfc2543Cancel: true,
          proxy: "sip:$androidHost",
          secret: password);
      debugPrint("Auto Registration triggered...");
    }catch(e){
      debugPrint("Cannot trigger auto register");
    }
  }


  Future<void> unRegister() async {
    sip?.unregister();
    debugPrint("Un registering");
  }

  Future<void> stopTracks() async {
    print("local stream start");
    print(mediaStream);
    print("local stream end");
    await stopAllTracksAndDispose(mediaStream);
  }

  Future<void> cleanUpWebRTCStuff() async {
    await stopTracks();
    _remoteVideoRenderer.srcObject = null;
    _remoteVideoRenderer.dispose();
  }


  muteUnmute(level, mute) async{
    // await sip?.muteUnmute(level, isMuted);
    var senders = await sip?.webRTCHandle?.peerConnection?.senders;
    senders?.forEach((element) {
      if (element.track?.kind == 'audio') {
        element.track?.enabled = mute;
      }
    });
  }

  Future<void> speakerPhoneState(bool speakerOn) async {
    var receivers = await sip?.webRTCHandle?.peerConnection?.receivers;
    receivers?.forEach((element) {
      if (element.track?.kind == 'audio') {
        element.track?.enabled = speakerOn;
      }
    });
  }


  Future<void> enableSpeakerMode(bool mode) async {
    var receivers = await sip?.webRTCHandle?.peerConnection?.receivers;
    receivers?.forEach((element) {
      print("Element : ${element.track?.kind}");
      if (element.track?.kind == 'audio') {
        element.track?.enableSpeakerphone(mode);
      }
    });

  }




  makeCall(mailbox, androidHost) async {
    await riseDatabase.setActive("outgoing");
    var newValue = "sip:$mailbox@$androidHost";
    debugPrint("Passing to make call : $newValue");
    await sip?.initializeWebRTCStack();
    await localStreamInitializer();
    var offer = await sip?.createOffer(videoRecv: false, audioRecv: true);
    await sip?.call(newValue, offer: offer, autoAcceptReInvites: false);
    await riseDatabase.insertHistory(mailbox, "outgoing");
  }

  decline() async{
    debugPrint("**********************************Declined Call*************************************");
    await sip?.decline();
  }

  accept() async{
    await localStreamInitializer();
    await sip?.handleRemoteJsep(rtc);
    var answer = await sip?.createAnswer();
    await sip?.accept(sessionDescription: answer);
    debugPrint("**********************************Call Accepted*************************************");
  }
}

