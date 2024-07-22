

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lecle_volume_flutter/lecle_volume_flutter.dart';
import 'package:rise/Resources/DatabaseConnection.dart';
import 'package:rise/Resources/Function.dart';
import 'package:rise/Resources/MyVibration.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:vibration/vibration.dart';



class MessagesWidget extends StatefulWidget {
  const MessagesWidget({super.key});

  @override
  State<MessagesWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<MessagesWidget> {
  static const platform = MethodChannel('com.example.app/ringtone');

  @override
  void dispose(){
    super.dispose();
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
              try {
                await riseDatabase.insertHistory("819", "incoming");
              } on PlatformException catch (e) {
                print("Failed ${e.message}.");
              }
            },
            child: const Text("Insert Incoming"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await riseDatabase.insertHistory("820", "outgoing");
              } on PlatformException catch (e) {
                print("Failed ${e.message}.");
              }
            },
            child: const Text("Insert Outgoing"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dynamic histories = await riseDatabase.selectLastCallHistory();

                print(histories['extension']);
              } on PlatformException catch (e) {
                print("Failed ${e.message}.");
              }
            },
            child: const Text("Get All History "),
          ),
        ],
      ),
    );
  }
}

