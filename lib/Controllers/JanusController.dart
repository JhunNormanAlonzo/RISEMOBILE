import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:rise/Resources/Janus/janus_client.dart';
import 'package:rise/Resources/Janus/janus_sip_manager.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/MyToast.dart';
import 'package:rise/Resources/Provider/CallProvider.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';
import 'package:rise/Resources/Provider/SipRegistrationProvider.dart';

class JanusController{

  static final JanusController _instance = JanusController._internal();

  factory JanusController() {
    return _instance;
  }

  JanusController._internal();

  JanusSipPlugin? sip;
  MediaStream? remoteVideoStream, remoteAudioStream, localStream, streamTrack;
  final RTCVideoRenderer _remoteVideoRenderer = RTCVideoRenderer();
  late JanusClient j;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  RTCTrackEvent? rtcTrackEvent;
  RTCPeerConnection? pc;
  RemoteTrack? remoteTrack;

  localStreamInitializer() async{
    localStream = await sip?.initializeMediaDevices(mediaConstraints: {'audio': true, 'video': false});
  }



  Future<void> initJanusClient(BuildContext context) async {
    final sipRegistrationProvider = Provider.of<SipRegistrationProvider>(context, listen: false);
    final navigationProvider =  Provider.of<NavigationProvider>(context, listen: false);
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    await JanusSipManager.instance.initializeSip();
    sip = JanusSipManager.instance.sipInstance;

    sip?.typedMessages?.listen((even) async {
      Object data = even.event.plugindata?.data;
      if (data is SipIncomingCallEvent) {
        await sip?.initializeWebRTCStack();
        await sip?.handleRemoteJsep(even.jsep);
        debugPrint("--------------------------------------INCOMING CALL ALERT----------------------------------------------");
        callProvider.setIn();
        navigationProvider.showOnCallWidget();
        myAudio.incoming();
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 1,
            channelKey: 'call_channel',
            title: "Calling",
            body: 'Diavox Call Notification',
            notificationLayout: NotificationLayout.BigText,
          ),
          // actionButtons: [
          //     NotificationActionButton(
          //       key: 'button-accept',
          //       label: 'Accept',
          //     ),
          //     NotificationActionButton(
          //       key: 'button-decline',
          //       label: 'Decline',
          //     ),
          //   ],
        );
      }
      if (data is SipAcceptedEvent) {
        debugPrint("--------------------------------------INCOMING CALL ACCEPTED EVENT START----------------------------------------------");
        await sip?.handleRemoteJsep(even.jsep);
        navigationProvider.showOnCallWidget();
      }
      if (data is SipHangupEvent) {
        await stopAllTracksAndDispose(localStream);
        myAudio.stop();
        debugPrint("--------------------------------------HANGUP EVENT RECEIVED----------------------------------------------");
        navigationProvider.hideOnCallWidget();
      }
      if(data is SipRegisteredEvent){
        debugPrint("--------------------------------------REGISTERED EVENT RECEIVED----------------------------------------------");
        FlutterBackgroundService().invoke("SipRegisteredEvent");
        debugPrint("--------------------------------------REGISTERED EVENT DONE----------------------------------------------");
        // sipRegistrationProvider.setRegistered();
        // toast.success(context, "SIP registered successfully");
        // navigationProvider.setIndex(0);
      }
    }, onError: (error) async {
      if (error is JanusError) {
        toast.error(context, error.error);
      }
    });
  }

  hangup() async{
    sip = JanusSipManager.instance.sipInstance;
    await sip?.hangup();
  }

  sendDtmf(number){
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
    // localStream = await sip?.initializeMediaDevices(mediaConstraints: {'audio': true, 'video': false});
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

final janus = JanusController();