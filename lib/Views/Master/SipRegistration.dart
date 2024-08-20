
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:rise/Components/Button.dart';
import 'package:rise/Components/InputField.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/BackJanusController.dart';
import 'package:rise/Controllers/JanusController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/MyToast.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:visibility_detector/visibility_detector.dart';



class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingState createState() => SettingState();
}

class SettingState extends State<Settings> {


  final TextEditingController _mailbox = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool showSidebar = true;
  // dynamic _setState;
  @override
  void initState() {
    super.initState();
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Center(
              child:  Text(
                "SIP Registration",
                style: TextStyle(
                    color: Pallete.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 50),
            InputField(placeholder: "Mailbox Number", controller: _mailbox, inputType: TextInputType.number),
            const SizedBox(height: 20),
            InputField(placeholder: "Password", controller: _password, inputType: TextInputType.text, isPassword: true),
            const SizedBox(height: 30),
            Button(
                label: "SIP Register",
                onPressed: () async{
                  try{
                    String username;
                    String password;
                    String androidHost;
                    username = _mailbox.text;
                    password = _password.text;
                    if(username.isEmpty || username == null){
                      username = await storageController.getData("mailboxNumber");
                    }

                    if(password.isEmpty || password == null){
                      password = "2241";
                    }


                    debugPrint("username : $username");
                    debugPrint("password : $password");

                    // Call registerUser with retrieved data
                    storageController.storeData("mailboxNumber", username);
                    storageController.storeData("password", password);
                    androidHost = await storageController.getData('androidHost');
                    username = await storageController.getData("mailboxNumber");
                    password = await storageController.getData("password");

                    FlutterBackgroundService().invoke('registerUser', {
                      'androidHost': androidHost,
                      'username': username,
                      'password': password
                    });
                  }catch(e){
                    toast.error(context, e.toString());
                  }
                }
            )
          ],
        ),
      ),
    );
  }



}
