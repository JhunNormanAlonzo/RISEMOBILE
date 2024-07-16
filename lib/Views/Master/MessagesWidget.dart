
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
import 'package:rise/Resources/DatabaseConnection.dart';
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
              final directory = await getApplicationDocumentsDirectory();
              debugPrint("the path is $directory");
            },
            // child: const Text("Clear Extension"),
            child: const Text("Show call status "),
          ),
        ],
      ),
    );
  }
}

