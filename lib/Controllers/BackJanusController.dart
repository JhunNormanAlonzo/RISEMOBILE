import 'dart:async';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/Janus/janus_client.dart';
import 'package:rise/Resources/Janus/janus_sip_manager.dart';

class BackJanusController{
  static final BackJanusController _instance = BackJanusController._internal();
  factory BackJanusController() => _instance;
  BackJanusController._internal();

  JanusSipPlugin? sip;
  MediaStream? remoteVideoStream, remoteAudioStream, localStream, streamTrack;
  final RTCVideoRenderer _remoteVideoRenderer = RTCVideoRenderer();
  late JanusClient j;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  RTCTrackEvent? rtcTrackEvent;
  RTCPeerConnection? pc;
  RemoteTrack? remoteTrack;

  final StreamController<String> _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageStreamController.stream;

  void sendMessageToFrontend(String message) {
    _messageStreamController.add(message);
  }

  void dispose() {
    _messageStreamController.close();
  }

  BuildContext? _context;

  void setContext(BuildContext context){
    _context = context;
  }

  localStreamInitializer() async{
    localStream = await sip?.initializeMediaDevices(mediaConstraints: {'audio': true, 'video': false});
  }

  Future<void> initJanusClient() async {

    await JanusSipManager.instance.initializeSip();
    sip = JanusSipManager.instance.sipInstance;

    sip?.typedMessages?.listen((even) async {
      Object data = even.event.plugindata?.data;


      if (data is SipIncomingCallEvent) {
        debugPrint("--------------------------------------INCOMING CALL ALERT EVENT----------------------------------------------");

        storageController.storeData("callStatus", "incoming");
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 2,
            channelKey: 'call_channel',
            title: "Call Notification",
            body: 'Call alarm!',
            duration: const Duration(seconds: 10)
          ),
        );

        await Future.delayed(const Duration(seconds: 1));


        debugPrint("Executing delayed WebRTC initialization and jsep handling");
        await sip?.initializeWebRTCStack();
        await sip?.handleRemoteJsep(even.jsep);
        debugPrint("sending set ready");
        IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipIncomingCallEvent');


        debugPrint("--------------------------------------INCOMING CALL ALERT DONE----------------------------------------------");
      }
      if (data is SipAcceptedEvent) {
        debugPrint("--------------------------------------INCOMING CALL ACCEPTED EVENT RECEIVED----------------------------------------------");
        await sip?.handleRemoteJsep(even.jsep);
        IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipAcceptedEvent');
        debugPrint("--------------------------------------INCOMING CALL ACCEPTED EVENT DONE----------------------------------------------");
        // navigationProvider.showOnCallWidget();
      }
      if (data is SipHangupEvent) {
        await stopAllTracksAndDispose(localStream);
        // myAudio.stop();

        debugPrint("--------------------------------------HANGUP EVENT RECEIVED----------------------------------------------");
        storageController.storeData("callStatus", "empty");
        IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipHangupEvent');
        AwesomeNotifications().cancel(2);
        debugPrint("--------------------------------------HANGUP EVENT DONE----------------------------------------------");
        // navigationProvider.hideOnCallWidget();
      }
      if(data is SipRegisteredEvent){
        debugPrint("--------------------------------------REGISTERED EVENT RECEIVED----------------------------------------------");
        IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipRegisteredEvent');
        storageController.storeData("janusConnection", "registered");
        debugPrint("--------------------------------------REGISTERED EVENT DONE----------------------------------------------");
      }

      if(data is SipCallingEvent){
        debugPrint("--------------------------------------Setting callStatus to Outgoing----------------------------------------------");
        storageController.storeData("callStatus", "outgoing");
        debugPrint("--------------------------------------SipCallingEvent EVENT RECEIVED----------------------------------------------");
      }

      if(data is SipMissedCallEvent){
        debugPrint("--------------------------------------Setting callStatus to empty----------------------------------------------");
        storageController.storeData("callStatus", "empty");
        debugPrint("--------------------------------------SipMissedCallEvent EVENT RECEIVED----------------------------------------------");
      }

      if(data is SipProceedingEvent){
        debugPrint("--------------------------------------SipProceedingEvent EVENT RECEIVED----------------------------------------------");
      }

      if(data is SipProgressEvent){
        debugPrint("--------------------------------------SipProgressEvent EVENT RECEIVED----------------------------------------------");

      }

      if(data is SipRingingEvent){
        debugPrint("--------------------------------------SipRingingEvent EVENT RECEIVED----------------------------------------------");
      }


      if(data is SipAcceptedEventResult){
        debugPrint("--------------------------------------SipAcceptedEventResult EVENT RECEIVED----------------------------------------------");
      }



    }, onError: (error) async {
      if (error is JanusError) {
        IsolateNameServer.lookupPortByName('mainIsolate')?.send('$error');
        // toast.error(_context!, error.error);
      }
    });
  }

  hangup() async{
    sip = JanusSipManager.instance.sipInstance;
    await sip?.hangup();
  }

  sendDtmf(number){
    sendMessageToFrontend("message to frontend");
    Map<String, dynamic> dtmf = {"tones": "$number"};
    sip?.sendDtmf(dtmf);
  }

  Future<void> registerUser(String ip, String username, String password) async {
    debugPrint("Triggering registration...");
    // localStream = await sip?.initializeMediaDevices(mediaConstraints: {'audio': true, 'video': false});
    // await localStreamInitializer();
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
      // localStream = await sip?.initializeMediaDevices(mediaConstraints: {'audio': true, 'video': false});
      // await localStreamInitializer();
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
    await stopAllTracksAndDispose(remoteAudioStream);
    await stopAllTracksAndDispose(remoteVideoStream);
  }

  Future<void> cleanUpWebRTCStuff() async {
    await stopTracks();
    _remoteVideoRenderer.srcObject = null;
    _remoteVideoRenderer.dispose();
  }


  muteUnmute(level, isMuted) async{
    await sip?.muteUnmute(level, isMuted);
  }

  makeCall(mailbox, androidHost) async {
    var newValue = "sip:$mailbox@$androidHost";
    debugPrint("Passing to make call : $newValue");
    await sip?.initializeWebRTCStack();

    await localStreamInitializer();
    var offer = await sip?.createOffer(videoRecv: false, audioRecv: true);
    await sip?.call(newValue, offer: offer, autoAcceptReInvites: false);
  }

  decline() async{
    await sip?.decline();
  }

  accept() async{
    // localStream = await sip?.initializeMediaDevices(mediaConstraints: {'audio': true, 'video': false});
    await localStreamInitializer();
    var answer = await sip?.createAnswer();
    await sip?.accept(sessionDescription: answer);
  }

  Future<void> stopAllTracksAndDispose(MediaStream? stream) async {
    if (stream != null) {
      stream.getTracks().forEach((track) => track.stop());
      await stream.dispose();
    }
  }
}

final backJanus = BackJanusController();