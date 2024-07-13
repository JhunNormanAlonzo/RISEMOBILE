import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:lecle_volume_flutter/lecle_volume_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:rise/Resources/Provider/CallProvider.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';
import 'package:rise/Views/Master/DialpadWidget.dart';


class OnCallWidget extends StatefulWidget {
  @override
  _OnCallWidgetState createState() => _OnCallWidgetState();
}

class _OnCallWidgetState extends State<OnCallWidget> {
  bool isMuted = false,
      isLoudSpeaker= false,
      isIncomingCall = false,
      isOngoingCall = false;

  bool isReady = false;

  final port = ReceivePort();

  dynamic incomingDialog, registerDialog, callDialog,  maxVol, currentVol;

  final List<String> dialPadNumbers = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '*', '0', '#'
  ];


  @override
  void initState() {
    super.initState();
    initAudioStreamType();
    _normalVolume();

    WidgetsBinding.instance.addPostFrameCallback((_) async{
      // final callStatus = await storageController.getData('callStatus');
      // debugPrint("call status is $callStatus");
      // if(callStatus == "outgoing"){
      //   setState(() {
      //     debugPrint("setting call state to ready");
      //     isReady = true;
      //   });
      // }


      // IsolateNameServer.removePortNameMapping('callIsolate');
      // IsolateNameServer.registerPortWithName(port.sendPort, 'callIsolate');
      // port.listen((msg) {
      //   debugPrint(msg);
      //   if(msg == "setReady"){
      //     debugPrint("setting call state to ready");
      //     setState(() {
      //       isReady = true;
      //     });
      //   }
      // });
    });




  }

  @override
  void dispose(){
    super.dispose();
  }
  bool showAcceptButton = true;


  @override
  Widget build(BuildContext context) {

    final callProvider = Provider.of<CallProvider>(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomLeft,
                colors: [Pallete.gradient4, Pallete.backgroundColor],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.person, size: 120, color: Colors.white),
                        LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white,
                          size: 40,
                        ),
                      ],
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        OnCallButton(
                          icon: !isLoudSpeaker ? Icons.volume_down : Icons.volume_up, color: Colors.white, size: 50,
                          onPressed: (){
                            if(!isLoudSpeaker){
                              setState(() {
                                isLoudSpeaker = true;
                                _loudVolume();
                              });
                            }else{
                              setState(() {
                                isLoudSpeaker = false;
                                _normalVolume();
                              });
                            }
                          },
                        )
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            if(callProvider.inOut == callProvider.incoming() && showAcceptButton)
                              ...[
                                OnCallButton(
                                  icon: Icons.phone_callback, color: Pallete.gradient4, size: 50,
                                  onPressed: (){
                                    myAudio.stop();
                                    AwesomeNotifications().cancel(2);
                                    FlutterBackgroundService().invoke('accept');
                                    setState(() {
                                      showAcceptButton = false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 50),
                              ],
                            OnCallButton(
                              icon: Icons.call_end, color: Colors.red, size: 50,
                              onPressed: () async {
                                final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                                FlutterBackgroundService().invoke('hangup');
                                FlutterBackgroundService().invoke('decline');
                                navigationProvider.hideOnCallWidget();
                                myAudio.stop();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    Column(
                      children: [
                        OnCallButton(
                          icon: !isMuted ? Icons.mic : Icons.mic_off, color: Colors.white, size: 50,
                          onPressed: (){
                            FlutterBackgroundService().invoke('muteUnmute',{
                              'flag' : '0',
                              'isMuted' : isMuted
                            });
                            setState(() {
                              isMuted =! isMuted;
                            });
                          },
                        )
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 60, right: 60),
              child: GridView.builder(
                itemCount: dialPadNumbers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 1.0,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  String number = dialPadNumbers[index];
                  return DialButton(
                    number: number,
                    onPressed: () => onNumberTapped(number),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );


    // return isReady ? Scaffold(
    //   body: Column(
    //     children: <Widget>[
    //       Container(
    //         decoration: const BoxDecoration(
    //           gradient: LinearGradient(
    //             begin: Alignment.topLeft,
    //             end: Alignment.bottomLeft,
    //             colors: [Pallete.gradient4, Pallete.backgroundColor],
    //           ),
    //         ),
    //         child: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               children: [
    //                 Column(
    //                   children: [
    //                     const Icon(Icons.person, size: 120, color: Colors.white),
    //                     LoadingAnimationWidget.staggeredDotsWave(
    //                       color: Colors.white,
    //                       size: 40,
    //                     ),
    //                   ],
    //                 )
    //               ],
    //             ),
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //               children: [
    //                 Column(
    //                   children: [
    //                     OnCallButton(
    //                       icon: !isLoudSpeaker ? Icons.volume_down : Icons.volume_up, color: Colors.white, size: 50,
    //                       onPressed: (){
    //                         if(!isLoudSpeaker){
    //                           setState(() {
    //                             isLoudSpeaker = true;
    //                             _loudVolume();
    //                           });
    //                         }else{
    //                           setState(() {
    //                             isLoudSpeaker = false;
    //                             _normalVolume();
    //                           });
    //                         }
    //                       },
    //                     )
    //                   ],
    //                 ),
    //                 Column(
    //                   children: [
    //                     Row(
    //                       children: [
    //                         if(callProvider.inOut == callProvider.incoming() && showAcceptButton)
    //                           ...[
    //                             OnCallButton(
    //                               icon: Icons.phone_callback, color: Pallete.gradient4, size: 50,
    //                               onPressed: (){
    //                                 myAudio.stop();
    //                                 AwesomeNotifications().cancel(2);
    //                                 FlutterBackgroundService().invoke('accept');
    //                                 setState(() {
    //                                   showAcceptButton = false;
    //                                 });
    //                               },
    //                             ),
    //                             const SizedBox(width: 50),
    //                           ],
    //                         OnCallButton(
    //                           icon: Icons.call_end, color: Colors.red, size: 50,
    //                           onPressed: () async {
    //                             final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    //                             FlutterBackgroundService().invoke('hangup');
    //                             FlutterBackgroundService().invoke('decline');
    //                             navigationProvider.hideOnCallWidget();
    //                             myAudio.stop();
    //                           },
    //                         ),
    //                       ],
    //                     )
    //                   ],
    //                 ),
    //                 Column(
    //                   children: [
    //                     OnCallButton(
    //                       icon: !isMuted ? Icons.mic : Icons.mic_off, color: Colors.white, size: 50,
    //                       onPressed: (){
    //                         FlutterBackgroundService().invoke('muteUnmute',{
    //                           'flag' : '0',
    //                           'isMuted' : isMuted
    //                         });
    //                         setState(() {
    //                           isMuted =! isMuted;
    //                         });
    //                       },
    //                     )
    //                   ],
    //                 )
    //               ],
    //             ),
    //           ],
    //         ),
    //       ),
    //       Expanded(
    //         child: Padding(
    //           padding: const EdgeInsets.only(top: 20, left: 60, right: 60),
    //           child: GridView.builder(
    //             itemCount: dialPadNumbers.length,
    //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //               crossAxisCount: 3,
    //               crossAxisSpacing: 10.0,
    //               mainAxisSpacing: 1.0,
    //               childAspectRatio: 1,
    //             ),
    //             itemBuilder: (context, index) {
    //               String number = dialPadNumbers[index];
    //               return DialButton(
    //                 number: number,
    //                 onPressed: () => onNumberTapped(number),
    //               );
    //             },
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // ) :  Center(
    //   child:Column(
    //     mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
    //     crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
    //     children: [
    //       const Text("Initializing. . .", style: TextStyle(color: Pallete.white, fontSize: 20, fontWeight: FontWeight.bold),),
    //       const SizedBox(height: 20),
    //       LoadingAnimationWidget.inkDrop(
    //         color: Pallete.gradient4,
    //         size: 40,
    //       ),
    //     ],
    //   ),
    // );
  }


  void setVol({int androidVol = 0, double iOSVol = 0.0}) async {
    await Volume.setVol(
        androidVol: androidVol,
        iOSVol: iOSVol,
        showVolumeUI: false
    );
  }


  void _normalVolume() async {
    try {
      setState(() {
        currentVol = 1.0;
        setVol(androidVol: currentVol.toInt(), iOSVol: currentVol);
        isLoudSpeaker = false;
      });
    } on PlatformException catch (e) {
      debugPrint('Error: ${e.message}');
    }
  }

  void _loudVolume() async {
    try {
      maxVol = await Volume.getMaxVol;
      setState(() {
        setVol(androidVol: maxVol.toInt(), iOSVol: maxVol.toDouble());
        isLoudSpeaker = true;
      });
    } on PlatformException catch (e) {
      debugPrint('Error: ${e.message}');
    }
  }

  Future<void> initAudioStreamType() async {
    await Volume.initAudioStream(AudioManager.streamVoiceCall);
  }


  onNumberTapped(number) {
    FlutterBackgroundService().invoke('dtmf',{
      'inputNumber' : number
    });
  }




}


class OnCallButton extends StatelessWidget{
  final IconData icon;
  final Color color;
  final double size;
  final Function()? onPressed;

  OnCallButton({required this.icon, required this.color, required this.size, this.onPressed});

  @override
  Widget build(BuildContext context){
    return InkWell(
      onTap: onPressed,
      child: Icon(icon, size: size, color: color),
    );
  }
}