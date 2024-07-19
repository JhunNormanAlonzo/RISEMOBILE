

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/Background/BackgroundWebsocket.dart';
import 'package:rise/Resources/Function.dart';
import 'package:rise/Resources/MyToast.dart';
import 'package:rise/Resources/Pallete.dart';



class MessagesWidget extends StatefulWidget {
  const MessagesWidget({super.key});

  @override
  State<MessagesWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<MessagesWidget> {
  @override
  void dispose(){
    super.dispose();
  }
  Future<void> autoRegister() async{
    try{
      final mailbox = await storageController.getData("mailboxNumber");
      final password = await storageController.getData("password");
      final androidHost = await storageController.getData('androidHost');
      FlutterBackgroundService().invoke('registerUser', {
        'androidHost': androidHost,
        'username': mailbox,
        'password': password
      });
    }catch(e){
      toast.error(context, "Error on auto register missing data");
      debugPrint("Cannot trigger auto register");
    }

  }

  @override
  Widget build(BuildContext context) {
    return  Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Coming Soon ...",
            style: TextStyle(
              color: Pallete.white,
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              // storageController.removeData("mailboxNumber");
              // storageController.storeData("callStatus", "outgoing");
              // final etst = await storageController.getData("callStatus");
              // debugPrint("the call status is is $etst");
              // final directory = await getApplicationDocumentsDirectory();
              // debugPrint("the path is $directory");

              // final gateway = await storageController.getData("gateway");
              // final ws = WebSocketJanusTransport(url: gateway);
              // debugPrint("getting janus status start");
              // await ws.getInfo();
              // debugPrint("getting janus status end" );

              FlutterBackgroundService().invoke('reconnect');

            },
            // child: const Text("Clear Extension"),
            child: const Text("Janus reconnect "),
          ),
          ElevatedButton(
            onPressed: () async {
             invoke('disposeJanusClient');
            },
            child: const Text("Janus Disconnect "),
          ),
          ElevatedButton(
            onPressed: () async {
              invoke('stopAllTracks');
            },
            child: const Text("stop tracks"),
          ),
          ElevatedButton(
            onPressed: () async {
              FlutterBackgroundService().invoke('muteUnmute',{
                'flag' : '0',
                'isMuted' : true
              });
            },
            child: const Text("true"),
          ),
        ],
      ),
    );
  }
}

