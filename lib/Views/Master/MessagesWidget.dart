
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/BackJanusController.dart';
import 'package:rise/Controllers/FileController.dart';
import 'package:rise/Controllers/JanusController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/MyToast.dart';
import 'package:rise/Resources/MyVibration.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:rise/Resources/Provider/CallProvider.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';


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
          Text("Messages Screen ${Provider.of<CallProvider>(context).inOut == true ? 'incoming' : 'outgoing'}", style: const TextStyle(
            color: Colors.red
          ),),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async{
              final navigationProvider =  Provider.of<NavigationProvider>(context, listen: false);
              // navigationProvider.setExtension("805");
              navigationProvider.showFireAlarmWidget();
            },
            child: const Text("Alert"),
          ),
          ElevatedButton(
            onPressed: (){
              final navigationProvider =  Provider.of<NavigationProvider>(context, listen: false);
              navigationProvider.hideOnCallWidget();
              myAudio.stop();
              vibrator.stop();
            },
            child: const Text("Stop"),
          ),
          ElevatedButton(
            onPressed: (){
              fileController.download("file to download", context);
            },
            child: const Text("Download"),
          ),
          ElevatedButton(
            onPressed: () {
              myAudio.danger();
            },
            child: const Text("Alarm Manager"),
          ),
          ElevatedButton(
            onPressed: () {
              FlutterBackgroundService().invoke("playRingtone");
            },
            child: const Text("Play Native Ringtone"),
          ),
          ElevatedButton(
            onPressed: () async {
              storageController.removeData("password");
              // Directory? appDocDir = await getExternalStorageDirectory();
              // String appDocPath = '${appDocDir?.path}/rise';
              // await Directory(appDocPath).create(recursive: true);
              // debugPrint(appDocPath);
              // File file1 = File('$appDocPath/ringing.mp3');
              // File file2 = File('$appDocPath/danger.mp3');
              // if (!await file1.exists()) {
              //   ByteData data = await rootBundle.load('assets/sounds/ringing.mp3');
              //   List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
              //   await file1.writeAsBytes(bytes);
              // }
              //
              // if (!await file2.exists()) {
              //   ByteData data = await rootBundle.load('assets/sounds/danger.mp3');
              //   List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
              //   await file2.writeAsBytes(bytes);
              // }
            },
            child: const Text("Storage"),
          ),

          ElevatedButton(
            onPressed: () async {

            },
            child: const Text("Play"),
          ),
        ],
      ),
    );
  }
}

