import 'dart:async';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/DatabaseConnection.dart';
import 'package:rise/Resources/Janus/janus_client.dart';
import 'package:rise/Resources/Pallete.dart';


class BackJanusController{
  BackJanusController._();
  static final BackJanusController _instance = BackJanusController._();
  static BackJanusController get instance => _instance;

  JanusSipPlugin? sip;
  RTCSessionDescription? rtc;
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

        if (data is SipIncomingCallEvent) {
          debugPrint("--------------------------------------INCOMING CALL ALERT EVENT----------------------------------------------");
          storageController.storeData("callStatus", "incoming");
          await riseDatabase.setActive("incoming");
          final lifecycle = await AwesomeNotifications().getAppLifeCycle();



          await sip?.initializeWebRTCStack();
          IsolateNameServer.lookupPortByName('backIsolate')?.send('SipIncomingCallEvent');

          debugPrint("Executing delayed WebRTC initialization and jsep handling");

          rtc = even.jsep;
          debugPrint("sending set ready");
          IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipIncomingCallEvent');

          if(lifecycle == NotificationLifeCycle.Background){
            AwesomeNotifications().createNotification(
                content: NotificationContent(
                    id: 2,
                    channelKey: 'call_channel',
                    title: "Call Notification",
                    body: 'Incoming call!',
                    duration: const Duration(seconds: 10)
                ),
                // actionButtons: [
                //   NotificationActionButton(key: 'ACCEPT', label: 'Accept', color: Pallete.gradient4),
                //   NotificationActionButton(key: 'DECLINE', label: 'Decline', color: Pallete.gradient3),
                // ]
            );
          }

          debugPrint("--------------------------------------INCOMING CALL ALERT DONE----------------------------------------------");
        }
        if (data is SipAcceptedEvent) {
          debugPrint("--------------------------------------INCOMING CALL ACCEPTED EVENT RECEIVED----------------------------------------------");
          await sip?.handleRemoteJsep(even.jsep);
          await riseDatabase.setAccepted(1);
          IsolateNameServer.lookupPortByName('mainIsolate')?.send('SipAcceptedEvent');
          debugPrint("--------------------------------------INCOMING CALL ACCEPTED EVENT DONE----------------------------------------------");
          // navigationProvider.showOnCallWidget();
        }
        if (data is SipHangupEvent) {
          await stopAllTracksAndDispose(localStream);
          // myAudio.stop();

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
          debugPrint("--------------------------------------SipProceedingEvent EVENT RECEIVED----------------------------------------------");
        }
        if (data is SipProgressEvent) {
          debugPrint("--------------------------------------SipProgressEvent EVENT RECEIVED----------------------------------------------");
        }
        if (data is SipRingingEvent) {
          debugPrint("--------------------------------------SipRingingEvent EVENT RECEIVED----------------------------------------------");
        }
        if (data is SipAcceptedEventResult) {
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

  // Future<void> disconnectSession() async {
  //   if (session != null) {
  //     await session.destroy();
  //     _session = null;
  //   }
  //   if (_janusClient != null) {
  //     await _janusClient.close();
  //     _janusClient = null;
  //   }
  // }

  hangup() async{
    debugPrint("**********************************Hangup Call*************************************");
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
    await riseDatabase.setActive("outgoing");
    var newValue = "sip:$mailbox@$androidHost";
    debugPrint("Passing to make call : $newValue");
    await sip?.initializeWebRTCStack();

    await localStreamInitializer();
    var offer = await sip?.createOffer(videoRecv: false, audioRecv: true);
    await sip?.call(newValue, offer: offer, autoAcceptReInvites: false);
  }

  decline() async{
    debugPrint("**********************************Declined Call*************************************");
    await sip?.decline();
  }

  accept() async{
    if (rtc == null) {
      throw Exception("RTCSessionDescription not available. Ensure proper retrieval from incoming call event.");
    }

    print("the rtc is : $rtc");
    await sip?.handleRemoteJsep(rtc);
    await localStreamInitializer();

    var answer = await sip?.createAnswer();
    await sip?.accept(sessionDescription: answer);
    debugPrint("**********************************Call Accepted*************************************");
  }


}
