

import 'dart:convert';
import 'dart:ui';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
  static const MethodChannel _channel = MethodChannel('com.example.app/audiotrack');

  bool isToggled = false;

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

