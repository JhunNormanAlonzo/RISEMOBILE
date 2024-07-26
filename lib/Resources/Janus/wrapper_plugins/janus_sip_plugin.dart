part of janus_client;

enum SipHoldState { SENDONLY, RECVONLY, INACTIVE }

class JanusSipPlugin extends JanusPlugin {
  @override
  // ignore: overridden_fields
  Map<String, dynamic>? webrtcStuff;
  bool _onCreated = false;
  JanusSipPlugin({
    handleId,
    context,
    transport,
    session,
    Map<String, dynamic>? webrtcConfig,
  }) : super(
            context: context,
            handleId: handleId,
            plugin: JanusPlugins.SIP,
            session: session,
            transport: transport) {
    // Initialize webrtcStuff here based on the provided webrtcConfig
    if (webrtcConfig != null) {
      webrtcStuff = {}; // Initialize webrtcStuff as a map

      // Do not use await here in the constructor
      // Instead, call an asynchronous initialization method
      // initializeWebrtc(webrtcConfig);
      initializeWebRTCStack();
    }
  }

  // Asynchronous initialization method
  Future<void> initializeWebrtc(Map<String, dynamic> webrtcConfig) async {
    RTCPeerConnection? pc = webRTCHandle?.peerConnection;

    print("----------------------- PEERCONNECTION === $pc");

    webrtcStuff?['pc'] = pc;
    webrtcStuff?['myStream'] = null;
    webrtcStuff?['dtmfSender'] = null;
    print("----------------------- WEBRTCSTUFF === $webrtcStuff");
  }

  /// Register client to sip server
  /// [username] : SIP URI to register
  /// [type] : if guest or helper, no SIP REGISTER is actually sent; optional
  /// [sendRegister] : true|false; if false, no SIP REGISTER is actually sent; optional
  Future<void> register(
    String username, {
    String? type,
    bool? sendRegister,
    bool? forceUdp,
    bool? forceTcp,
    bool? sips,
    bool? rfc2543Cancel,
    bool? refresh,
    String? secret,
    String? ha1Secret,
    String? authuser,
    String? displayName,
    String? userAgent,
    String? proxy,
    String? outboundProxy,
    Map<String, dynamic>? headers,
    List<Map<String, dynamic>>? contactParams,
    List<String>? incomingHeaderPrefixes,
    String? masterId,
    int? registerTtl,
  }) async {


    var payload = {
      "request": "register",
      "type": type,
      "send_register": sendRegister,
      "force_udp":
          forceUdp, //<true|false; if true, forces UDP for the SIP messaging; optional>,
      "force_tcp":
          forceTcp, //<true|false; if true, forces TCP for the SIP messaging; optional>,
      "sips":
          sips, //<true|false; if true, configures a SIPS URI too when registering; optional>,
      "rfc2543_cancel":
          rfc2543Cancel, //<true|false; if true, configures sip client to CANCEL pending INVITEs without having received a provisional response first; optional>,
      "username": username,
      "secret": secret, //"<password to use to register; optional>",
      "ha1_secret":
          ha1Secret, //"<prehashed password to use to register; optional>",
      "authuser":
          authuser, //"<username to use to authenticate (overrides the one in the SIP URI); optional>",
      "display_name":
          displayName, //"<display name to use when sending SIP REGISTER; optional>",
      "user_agent":
          userAgent, //"<user agent to use when sending SIP REGISTER; optional>",
      "proxy":
          proxy, //"<server to register at; optional, as won't be needed in case the REGISTER is not goint to be sent (e.g., guests)>",
      "outbound_proxy":
          outboundProxy, //"<outbound proxy to use, if any; optional>",
      "headers":
          headers, //"<object with key/value mappings (header name/value), to specify custom headers to add to the SIP REGISTER; optional>",
      "contact_params":
          contactParams, //"<array of key/value objects, to specify custom Contact URI params to add to the SIP REGISTER; optional>",
      "incoming_header_prefixes":
          incomingHeaderPrefixes, //"<array of strings, to specify custom (non-standard) headers to read on incoming SIP events; optional>",
      "refresh":
          refresh, //"<true|false; if true, only uses the SIP REGISTER as an update and not a new registration; optional>",
      "master_id":
          masterId, //"<ID of an already registered account, if this is an helper for multiple calls (more on that later); optional>",
      "register_ttl":
          registerTtl, //"<integer; number of seconds after which the registration should expire; optional>"
    }..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// Accept Incoming Call
  ///
  /// [sessionDescription] : For accepting the call we can have offerless sip invite too, so here we have intententionaly given flexibility of having either offer or answer depending on what peer is providing  if it is not provided, default offer or answer is created and used with audio as sendrecv depending on the signaling state
  ///
  /// [headers] : object with key/value mappings (header name/value), to specify custom headers to add to the SIP INVITE; optional
  ///
  /// [srtp] : whether to mandate (sdes_mandatory) or offer (sdes_optional) SRTP support; optional
  ///
  /// [autoAcceptReInvites] : whether we should blindly accept re-INVITEs with a 200 OK instead of relaying the SDP to the application; optional, TRUE by default
  Future<void> accept(
      {String? srtp,
      Map<String, dynamic>? headers,
      bool? autoAcceptReInvites,
      RTCSessionDescription? sessionDescription}) async {
    var payload = {
      "request": "accept",
      "headers": headers,
      "srtp": srtp,
      "autoaccept_reinvites": autoAcceptReInvites
    }..removeWhere((key, value) => value == null);
    RTCSignalingState? signalingState =
        this.webRTCHandle?.peerConnection?.signalingState;
    if (sessionDescription == null &&
        signalingState == RTCSignalingState.RTCSignalingStateHaveRemoteOffer) {
      sessionDescription = await this.createAnswer();
    } else if (sessionDescription == null) {
      sessionDescription =
          await this.createOffer(videoRecv: false, audioRecv: true);
    }
    JanusEvent response = JanusEvent.fromJson(
        await this.send(data: payload, jsep: sessionDescription));
    JanusError.throwErrorFromEvent(response);
  }


  /// unregister from the SIP server.
  Future<void> unregister() async {
    const payload = {"request": "unregister"};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// hangup the call
  /// [headers]: object with key/value mappings (header name/value), to specify custom headers to add to the SIP BYE; optional
  Future<void> hangup({
    Map<String, dynamic>? headers,
  }) async {

    var payload = {"request": "hangup", "headers": headers}
      ..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// decline sip call
  /// [code] : SIP code to be sent, if not set, 486 is used; optional
  /// [headers] : object with key/value mappings (header name/value), to specify custom headers to add to the SIP request; optional
  Future<void> decline({
    int? code,
    Map<String, dynamic>? headers,
  }) async {
    var payload = {"request": "decline", "code": code, "headers": headers}
      ..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// hold sip call
  /// [direction] : specify [SipHoldState] for direction of call flow
  Future<void> hold(
    SipHoldState direction,
  ) async {
    var payload = {"request": "hold", "direction": direction.name};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// unhold sip call
  Future<void> unhold() async {
    var payload = {"request": "unhold"};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// update sip session
  Future<void> update() async {
    const payload = {"request": "update"};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// initiate sip call invite to provided sip uri.
  /// [uri] : SIP URI to call; mandatory
  /// [callId] : user-defined value of Call-ID SIP header used in all SIP requests throughout the call; optional
  /// [referId] : in case this is the result of a REFER, the unique identifier that addresses it; optional
  /// [headers] : object with key/value mappings (header name/value), to specify custom headers to add to the SIP INVITE; optional
  /// [srtp] : whether to mandate (sdes_mandatory) or offer (sdes_optional) SRTP support; optional
  /// [srtpProfile] : SRTP profile to negotiate, in case SRTP is offered; optional
  /// [autoAcceptReInvites] : whether we should blindly accept re-INVITEs with a 200 OK instead of relaying the SDP to the application; optional, TRUE by default
  /// [offer] : note it by default sends only audio sendrecv offer
  Future<void> call(String uri,
      {String? callId,
      String? referId,
      String? srtp,
      String? secret,
      String? ha1Secret,
      String? authuser,
      Map<String, dynamic>? headers,
      String? srtpProfile,
      bool? autoAcceptReInvites,
      RTCSessionDescription? offer}) async {
    var payload = {
      "request": "call",
      "call_id": callId,
      "uri": uri,
      "refer_id": referId,
      "headers": headers,
      "autoaccept_reinvites": autoAcceptReInvites,
      "srtp": srtp,
      "srtp_profile": srtpProfile,
      "secret": secret, //"<password to use to register; optional>",
      "ha1_secret":
          ha1Secret, //"<prehashed password to use to register; optional>",
      "authuser":
          authuser, //"<username to use to authenticate (overrides the one in the SIP URI); optional>",
    }..removeWhere((key, value) => value == null);
    if (offer == null) {
      offer = await this.createOffer(videoRecv: false, audioRecv: true);
    }
    JanusEvent response =
        JanusEvent.fromJson(await this.send(data: payload, jsep: offer));
    JanusError.throwErrorFromEvent(response);
  }

  /// transfer on-going call to another sip uri
  /// [uri] : SIP URI to send the transferee too
  /// [replace]: call-ID of the call this attended transfer is supposed to replace; default is none, which means blind/unattended transfer
  Future<void> transfer(
    String uri, {
    String? replace,
  }) async {
    var payload = {"request": "transfer", "uri": uri, "replace": replace}
      ..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// record on-going call
  /// [state] : true|false, depending on whether you want to start or stop recording something
  /// [audio]: true|false; whether or not our audio should be recorded
  /// [video]: true|false; whether or not our video should be recorded
  /// [peerAudio]: true|false; whether or not our peer's audio should be recorded
  /// [peerVideo]: true|false; whether or not our peer's video should be recorded
  /// [filename]: base path/filename to use for all the recordings
  Future<void> recording(
    bool state, {
    bool? audio,
    bool? video,
    bool? peerAudio,
    bool? peerVideo,
    String? filename,
  }) async {
    JanusEvent? response;

    var payload = {
      "request": "recording",
      "action": state ? "start" : 'stop',
      "audio": audio,
      "video": video,
      "peer_audio": peerAudio,
      "peer_video": peerVideo,
      "filename": filename
    }..removeWhere((key, value) => value == null);
    response = JanusEvent.fromJson(await this.send(data: payload));

    JanusError.throwErrorFromEvent(response);
  }

  @override
  void onCreate() {
    super.onCreate();
    if (_onCreated) {
      return;
    }
    _onCreated = true;
    messages?.listen((event) {
      TypedEvent<JanusEvent> typedEvent = TypedEvent<JanusEvent>(
          event: JanusEvent.fromJson(event.event), jsep: event.jsep);
      var data = typedEvent.event.plugindata?.data;

      if (data == null) return;

      if (data["sip"] == "event" && data["result"]?['event'] == "registered") {
        typedEvent.event.plugindata?.data = SipRegisteredEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "unregistered") {
        typedEvent.event.plugindata?.data = SipUnRegisteredEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "ringing") {
        typedEvent.event.plugindata?.data =
            SipRingingEvent.fromJson(typedEvent.event.plugindata?.data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "calling") {
        typedEvent.event.plugindata?.data = SipCallingEvent.fromJson(data);
        print("WE ARE TRYING TO CALL.........");
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "proceeding") {
        typedEvent.event.plugindata?.data = SipProceedingEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "accepted") {
        typedEvent.event.plugindata?.data = SipAcceptedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "progress") {
        typedEvent.event.plugindata?.data = SipProgressEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "incomingcall") {
        typedEvent.event.plugindata?.data = SipIncomingCallEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "missed_call") {
        typedEvent.event.plugindata?.data = SipMissedCallEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "transfer") {
        typedEvent.event.plugindata?.data = SipTransferCallEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['result']?['code'] != null &&
          data["result"]?['event'] == "hangup" &&
          data['result']?['reason'] != null) {
        typedEvent.event.plugindata?.data = SipHangupEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['sip'] == 'event' && data['error_code'] != null) {
        _typedMessagesSink?.addError(JanusError.fromMap(data));
      } else if (data["sip"] == "event" &&
          data["result"]?['event'] == "registration_failed") {
        print("you failed to register your ext");
        print(data);
        _typedMessagesSink?.addError(JanusError.fromMap(data));
      }
    });
  }


  // Future<void> muteUnmute(String mid, bool mute) async {
  //   JanusPlugin? pluginHandle = _session?._pluginHandles[handleId];
  //   pluginHandle!.webrtcStuff!;
  //   var pc = pluginHandle.webRTCHandle?.peerConnection;
  //
  //   List<RTCRtpTransceiver>? transceivers = await pc?.getTransceivers();
  //   for (var transceiver in transceivers ?? []) {
  //     if (transceiver.mid == mid) {
  //       transceiver.sender.track?.enabled = mute;
  //     }
  //   }
  //
  //
  // }



  Future<void> sendDtmf(Map<String, dynamic> dtmf) async {
    print("DTMF PARAM : $dtmf");
    print("HANDLE ID : $handleId");
    //JanusPlugin? pluginHandle = _session!._pluginHandles[handleId];
    JanusPlugin? pluginHandle = _session?._pluginHandles[handleId];
    if (pluginHandle == null) {
      return;
    }
    if (pluginHandle.webrtcStuff == null) {

      return;
    }

    Map<String, dynamic> config = pluginHandle.webrtcStuff!;
    if (config['dtmfSender'] == null) {

      // Create the DTMF sender the proper way, if possible
      var pc = pluginHandle.webRTCHandle?.peerConnection;
      if (pc != null) {
        //var pc = await config['pc'];
        //Future<List<RTCRtpSender>> senders = pc.getSenders();
        List<RTCRtpSender>? senders = await pc.getSenders();


        RTCRtpSender? audioSender;

        // Iterate through the senders list
        for (var sender in senders!) {
          if (sender.track != null && sender.track?.kind == 'audio') {
            audioSender = sender;
            break; // Found the audio sender, so exit the loop
          }
        }
        if (audioSender == null) {
          return;
        }


        RTCDTMFSender dtmfSender = audioSender.dtmfSender;
        // ignore: unnecessary_null_comparison
        if (dtmfSender != null) {
          print("Created DTMF Sender $dtmfSender");

          /* RTCDTMFSender dtmfSender = config['dtmfSender'];
          dtmfSender.ontonechange = (RTCDTMFToneChangeEvent event) {
            print("Sent DTMF tone: ${event.tone}");
          }; */
          var tones = dtmf['tones'];
          //dtmfSender.sendDtmf(tones);
          dtmfSender.insertDTMF(tones);

          /* config['dtmfSender']['ontonechange'] = (tone) {
            print("Sent DTMF tone: ${tone['tone']}");
          }; */
          print("________sendDTMF SENT!!!!!!!!!!!!!");
        }
      }

      /* if (config['dtmfSender'] == null) {
        print("Invalid DTMF configuration");
        print(
            "EEEEEEEEEEERRRRRRRRRRRRRRROOOOOOOOOOOOOOOOOOOOOORRRRRRRRRRRRRRRRRRR 3333333333333333333!!!!");
        return;
      } */
    }

    /* dtmf = dtmf ?? {};
    var tones = dtmf['tones'];

    if (tones == null) {
      print("Invalid DTMF string");
      print(
          "EEEEEEEEEEERRRRRRRRRRRRRRROOOOOOOOOOOOOOOOOOOOOORRRRRRRRRRRRRRRRRRR 4444444444444!!!!");
      return;
    }

    var duration =
        (dtmf['duration'] is num) ? dtmf['duration'] : 500; // Default duration
    var gap = (dtmf['gap'] is num) ? dtmf['gap'] : 50; // Default gap

    print("Sending DTMF string $tones (duration $duration ms, gap $gap ms)");
    config['dtmfSender']
        .insertDTMF(tones.toString(), duration.toInt(), gap.toInt()); */
  }



}
class WebRtcStuff {
  RTCPeerConnection? pc;
  MediaStream? myStream;

  WebRtcStuff({this.pc, this.myStream});
}