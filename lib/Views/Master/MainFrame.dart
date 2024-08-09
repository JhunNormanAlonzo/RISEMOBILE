
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/DatabaseConnection.dart';
import 'package:rise/Resources/ForegroundService.dart';
import 'package:rise/Resources/Function.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/MyToast.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:rise/Resources/Provider/CallProvider.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';
import 'package:rise/Views/Master/CallHistoryWidget.dart';
import 'package:rise/Views/Master/DialpadWidget.dart';
import 'package:rise/Views/Master/FireWidget.dart';
import 'package:rise/Views/Master/MessagesWidget.dart';
import 'package:rise/Views/Master/OnCallWidget.dart';
import 'package:rise/Views/Master/SipRegistration.dart';




class MainFrame extends StatefulWidget {
  const MainFrame({Key? key}) : super(key: key);

  @override
    MainFrameState createState() => MainFrameState();
  }

class MainFrameState extends State<MainFrame>{
  final audioPlayer = AudioPlayer();
  final port = ReceivePort();

  int selectedIndex = 0;

  late String janusConnection;

  bool showSipStatus = false;
  late bool showMessage;


  Future<int> getMessageCount() async {
    final response = await api.getMessages();
    final count = response['total_messages'];
    return count;
  }

  Future<void> _syncMessageWaitingStatus() async {
    final count = await getMessageCount();
    setState(() {
      showMessage = count > 0;
    });
  }

  @override
  void initState(){

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async{
      await initializeService(); //to run websocket and janus background.
      await _syncMessageWaitingStatus();
      IsolateNameServer.removePortNameMapping('mainIsolate');
      IsolateNameServer.registerPortWithName(port.sendPort, 'mainIsolate');
      final navigationProvider =  Provider.of<NavigationProvider>(context, listen: false);
      final callProvider = Provider.of<CallProvider>(context, listen: false);
      final callStatus = await storageController.getData("callStatus");
      if(callStatus == 'incoming'){

        setState(() {
          janusConnection = "registered";
        });
      }else{
        setState(() {
          janusConnection = "unregistered";
        });
      }
      await storageController.storeData("janusConnection", janusConnection);
      janusConnection = await storageController.getData("janusConnection");
      debugPrint("Janus Connection is $janusConnection");

      // Listen for messages from the background isolate
      port.listen((msg) async{
        debugPrint("Message is : $msg");
        if(msg == "SipRegisteredEvent"){
          _syncMessageWaitingStatus();
          setState(() {
            debugPrint("Setting state if registered");
            janusConnection = "registered";
          });
          AwesomeNotifications().cancel(3);
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: 3,
                channelKey: 'connection_channel',
                title: "SIP Notification",
                body: 'Connected',
                duration: const Duration(seconds: 10)
            ),
          );
          debugPrint("equal to SipRegisteredEvent");
          // toast.success(context, "SIP registered successfully");

          setState(() {
            showSipStatus = true;
          });
          navigationProvider.setIndex(0);
        }else if(msg == "SipHangupEvent"){
          myAudio.stop();
          navigationProvider.hideOnCallWidget();
        }else if(msg == "SipAcceptedEvent"){
          debugPrint("getting the call status");
          final outgoing = await riseDatabase.getStatus("outgoing");
          debugPrint("it is outgoing $outgoing");
          if(outgoing == 1){
            navigationProvider.showOnCallWidget();
          }
        }else if(msg == "SipUnRegisteredEvent"){
          setState(() {
            showMessage = false;
          });
        }else if(msg == "SipIncomingCallEvent"){
          callProvider.setIn();
          navigationProvider.showOnCallWidget();
          await myAudio.incoming();
        }else if(msg.startsWith('FireAlarmEvent-')){
          const prefix = "FireAlarmEvent-";
          final extension = msg.substring(prefix.length);
          final navigationProvider =  Provider.of<NavigationProvider>(context, listen: false);
          navigationProvider.setExtension(extension);
          navigationProvider.showFireAlarmWidget();
          myAudio.danger();
          FlutterBackgroundService().invoke('startVibration');
        }else if(msg.startsWith('MessageWaitingEvent-')){
          final response = await api.getMessages();
          print("total messages: ${response['total_messages']}.");
          if(response['total_messages'] > 0){
            setState(() {
              showMessage = true;
            });
          }else{
            setState(() {
              showMessage = false;
            });
          }
        }else if(msg.startsWith('JanusError')){
          RegExp regExp = RegExp(r'error:\s(.*)\s\((\d+)\),');
          Match? match = regExp.firstMatch(msg);
          if (match != null) {
            String errorMessage = match.group(1) ?? '';
            String errorCode = match.group(2) ?? '';

            if(errorMessage == "Already registered"){
              setState(() {
                debugPrint("Setting state if registered");
                janusConnection = "registered";
                storageController.storeData("janusConnection", "registered");
                setState(() {
                  showSipStatus = true;
                });
              });
            }else{
              toast.error(context, "$errorMessage $errorCode");
            }
          } else {
            print('No error message found');
          }
        }
        // Handle the data received from ForegroundService
      });


      if(callStatus == "incoming"){
        setState(() {
          showSipStatus = true;
        });
        callProvider.setIn();
        navigationProvider.showOnCallWidget();
      }
    });
    Future.delayed(const Duration(seconds: 5), () async{
      debugPrint("auto registering on init state");

      final mailbox = await storageController.getData("mailboxNumber");
      final password = await storageController.getData("password");
      final androidHost = await api.getAndroidHost();

      debugPrint("the password is : $password");

      if(password.isEmpty){
        debugPrint("the password is null");
      }else{
        debugPrint("the password is not null");
      }
      if (mailbox.isNotEmpty && password.isNotEmpty && androidHost!.isNotEmpty) {
        FlutterBackgroundService().invoke('autoRegister');
      } else {
        // toast.warning(context, 'mailbox : $mailbox | password:${password.isEmpty ? "none" : password}  \n androidHost=$androidHost');
        setState(() {
          showSipStatus = true;
        });
      }


    });
  }




  @override
  Widget build(BuildContext context) {
    return showSipStatus == false ?
    checkingSipRegistrationWidget() : PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        return await showDialog(
            context: context,
            builder: (BuildContext context){
              return AlertDialog(
                title: const Text('Are you sure?'),
                content:  const Text('Press back again to exit.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Don't exit app
                    },
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Exit app
                    },
                    child: const Text('Yes'),
                  ),
                ],
              );
            }
        );
      },
      child: frame(context),
    );
  }






  Widget frame(BuildContext context){
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final List<Widget> widgets = [
      DialpadWidget(),
      // const MessagesWidget(),
      const CallHistoryWidget(),
      const MessagesWidget(),
      const Settings(),
      if (navigationProvider.showOnCall)...[
        OnCallWidget(),
      ],
      if (navigationProvider.showFireAlarm)...[
        const FireWidget(),
      ]
    ];
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        // title:  const Text("RISE", style: TextStyle(color: Pallete.gradient4, fontWeight: FontWeight.bold),),
        title: Row(
          children: [
            const Text("RISE", style: TextStyle(color: Pallete.gradient4, fontWeight: FontWeight.bold),),
            const SizedBox(width: 20),
            FutureBuilder<dynamic>(
              future: storageController.getData("mailboxNumber"),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Row(
                    children: [
                      Text(
                        snapshot.data!,
                        style:  const TextStyle(
                            color: Pallete.gradient1,
                            fontWeight: FontWeight.bold,
                            fontSize: 18
                        ),
                      ),
                    ],
                  );

                } else if (snapshot.hasError) {
                  return const Text('No Extension Detected');
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
        actions: [
          if(showSipStatus == true)...[
            Row(
              children: [
                const SizedBox(width: 20),
                showMessage ? SwingingIcon(showMessage: true) : const SizedBox.shrink(),

                Container(
                  margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                  padding: const EdgeInsets.all(2.0), // Adjust the padding as needed
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color if needed
                    border: Border.all(
                      color: janusConnection == "registered" ? Pallete.gradient1 : Pallete.gradient3, // Border color
                      width: 2.0, // Border width
                    ),
                    borderRadius: BorderRadius.circular(8.0), // Border radius
                  ),
                  child: Text(
                    janusConnection == "registered" ? "REGISTERED" : "UNREGISTERED",
                    style: TextStyle(
                      color: janusConnection == "registered" ? Pallete.gradient1 : Pallete.gradient3,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            )
          ],
        ],
      ),
      drawer: Drawer(
        backgroundColor: Pallete.gradient4,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 40.0, right: 40.0),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Image.asset('assets/images/diavox.jpg'),
                const SizedBox(height: 40),
                FutureBuilder<dynamic>(
                  future: storageController.getData("mailboxNumber"),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!,
                        style: const TextStyle(
                            color: Pallete.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 50
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return const Text('No Extension Detected');
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                // const SizedBox(height: 20),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Expanded(
                //       child: ElevatedButton.icon(
                //         onPressed: (){
                //           final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                //           myAudio.stop();
                //           FlutterBackgroundService().invoke('stopVibration');
                //           navigationProvider.hideFireAlarmWidget();
                //         },
                //         style: ElevatedButton.styleFrom(
                //             backgroundColor: Pallete.backgroundColor
                //         ),
                //
                //         label: const Text(
                //           "Stop Alarm",
                //           style: TextStyle(
                //               color: Pallete.white,
                //               fontSize: 13,
                //               fontWeight: FontWeight.bold
                //           ),
                //         ),
                //         icon: const Icon(Icons.local_fire_department, color: Pallete.gradient3),
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (){
                          if (janusConnection == "registered") {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Pallete.white.withOpacity(1),
                                  title: const Text("Un-Register ?", style: TextStyle(
                                      color: Pallete.gradient4,
                                      fontWeight: FontWeight.bold
                                  ),),
                                  content: const Text('Are you sure you want to unregister to webrtc?',
                                    style: TextStyle(
                                        color: Pallete.backgroundColor,
                                        fontWeight: FontWeight.bold
                                    ),),
                                  actions: <Widget>[
                                    Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () async{
                                              await storageController.storeData("janusConnection", "unregistered");
                                              setState(() {
                                                janusConnection = "unregistered";
                                              });
                                              invoke('hangup');
                                              FlutterBackgroundService().invoke('unRegister');
                                              Navigator.of(context).pop();
                                            },
                                            style: ButtonStyle(
                                              backgroundColor: MaterialStateProperty.all<Color>(Pallete.gradient3),
                                            ),
                                            child:  const Text('Proceed',
                                              style: TextStyle(
                                                color: Pallete.white,
                                                fontWeight: FontWeight.w900,
                                              ),),
                                          ),
                                          TextButton(
                                            child: const Text('Close', style: TextStyle(
                                                color: Pallete.backgroundColor,
                                                fontWeight: FontWeight.bold
                                            ),),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Pallete.backgroundColor
                        ),

                        label: const Text(
                          "WebRTC Unregister",
                          style: TextStyle(
                              color: Pallete.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        icon: const Icon(Icons.delete, color: Pallete.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async{
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Pallete.white.withOpacity(1),
                                title: const Text("Attention!", style: TextStyle(
                                    color: Pallete.gradient4,
                                    fontWeight: FontWeight.bold
                                ),),
                                content: const Text('You are required to scan QR code?',
                                  style: TextStyle(
                                      color: Pallete.backgroundColor,
                                      fontWeight: FontWeight.bold
                                  ),),
                                actions: <Widget>[
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () async{
                                            await storageController.removeData("gateway");
                                            await storageController.removeData("base");
                                            await storageController.removeData("appKey");
                                            await storageController.removeData("androidHost");
                                            await storageController.removeData("appId");
                                            await storageController.removeData("accessToken");
                                            await storageController.storeData("janusConnection", "unregistered");
                                            exit(0);
                                          },
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all<Color>(Pallete.gradient3),
                                          ),
                                          child:  const Text('Agree',
                                            style: TextStyle(
                                              color: Pallete.white,
                                              fontWeight: FontWeight.w900,
                                            ),),
                                        ),
                                        TextButton(
                                          child: const Text('Close', style: TextStyle(
                                              color: Pallete.backgroundColor,
                                              fontWeight: FontWeight.bold
                                          ),),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Pallete.gradient5
                        ),
                        icon: const Icon(Icons.directions_boat, color: Pallete.gradient4),
                        label: const Text(
                          "Switch Ship",
                          style: TextStyle(
                              color: Pallete.backgroundColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async{
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Pallete.white.withOpacity(1),
                                title: const Text("Diavox Rise", style: TextStyle(
                                    color: Pallete.gradient4,
                                    fontWeight: FontWeight.bold
                                ),),
                                content: const Text('Are you sure you want to shutdown the app?',
                                  style: TextStyle(
                                      color: Pallete.backgroundColor,
                                      fontWeight: FontWeight.bold
                                  ),),
                                actions: <Widget>[
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () async{
                                            await storageController.storeData("janusConnection", "unregistered");
                                            exit(0);
                                          },
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all<Color>(Pallete.gradient3),
                                          ),
                                          child:  const Text('Shutdown',
                                            style: TextStyle(
                                              color: Pallete.white,
                                              fontWeight: FontWeight.w900,
                                            ),),
                                        ),
                                        TextButton(
                                          child: const Text('Close', style: TextStyle(
                                              color: Pallete.backgroundColor,
                                              fontWeight: FontWeight.bold
                                          ),),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.power_settings_new_rounded, color: Pallete.gradient3),
                        label: const Text(
                          "Disconnect",
                          style: TextStyle(
                              color: Pallete.backgroundColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),

        ),
      ),
      body:  SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: IndexedStack(
                      index: janusConnection == "unregistered" ? 3 : navigationProvider.selectedIndex,
                      children: widgets
                  ),
                ),
              ),
              BottomNavigationBar(
                backgroundColor: Colors.white,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dialpad),
                    label: 'Dialpad',
                  ),
                  // const BottomNavigationBarItem(
                  //   icon: Icon(Icons.record_voice_over),
                  //   label: 'Records',
                  // ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'Call History',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.message),
                    label: 'Messages',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Setting',
                  ),
                  if (navigationProvider.showOnCall)...[
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.call_made),
                      label: 'OnCall',
                    ),
                  ],
                  if (navigationProvider.showFireAlarm)...[
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.fireplace),
                      label: 'Fire Alarm',
                    ),
                  ],

                ],
                currentIndex: janusConnection == "unregistered" ? 3 : navigationProvider.selectedIndex,
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
                onTap: (index) {
                  debugPrint("index : ${navigationProvider.selectedIndex}");
                  // if (!navigationProvider.showOnCall && index == 3) return;
                  janusConnection == "unregistered" ? navigationProvider.setIndex(3) : navigationProvider.setIndex(index) ;
                },
              ),
            ],
          )
      ),
    );
    // return DefaultTabController(
    //   length: 3, // Number of tabs
    //   child: Scaffold(
    //     appBar: AppBar(
    //       title: Text('Top Navigation with Tabs'),
    //       bottom: TabBar(
    //         tabs: [
    //           Tab(icon: Icon(Icons.home), text: 'Home'),
    //           Tab(icon: Icon(Icons.search), text: 'Search'),
    //           Tab(icon: Icon(Icons.account_circle), text: 'Profile'),
    //         ],
    //       ),
    //     ),
    //     body: TabBarView(
    //       children: [
    //         Center(child: Text('Home Page', style: TextStyle(color: Colors.white),)),
    //         Center(child: Text('Search Page', style: TextStyle(color: Colors.white))),
    //         Center(child: Text('Profile Page', style: TextStyle(color: Colors.white))),
    //       ],
    //     ),
    //   ),
    // );
  }

  Widget checkingSipRegistrationWidget(){
    return  Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Connecting to WebRTC",
                  style: TextStyle(
                      color: Pallete.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24
                  ),
                ),
                const SizedBox(height: 20,),
                LoadingAnimationWidget.discreteCircle(
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              showSipStatus = true;
                            });
                          },
                          icon:  Icon(
                              Icons.bar_chart_sharp,
                              color: Pallete.white.withOpacity(0.7)
                          ),
                          label:  Text(
                            "Wait on Interface",
                            style: TextStyle(
                                color: Pallete.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Pallete.backgroundColor.withOpacity(0.7),
                            side:  const BorderSide(
                                color: Pallete.white,
                                width: 2
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )

              ],
            )
          )
        )
    );
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('mainIsolate');
    port.close();
    super.dispose();
  }


}



class SwingingIcon extends StatefulWidget {
  final bool showMessage;

  SwingingIcon({required this.showMessage});

  @override
  _SwingingIconState createState() => _SwingingIconState();
}

class _SwingingIconState extends State<SwingingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.showMessage
        ? RotationTransition(
      turns: _animation,
      child: const Icon(Icons.mail, color: Pallete.gradient3, size: 20,),
    )
        : const SizedBox.shrink();
  }
}



