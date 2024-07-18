
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:http/http.dart' as http;

class CoreController{


  Future<dynamic> generateAccessToken(dynamic username, dynamic password) async{
    final appId = await storageController.getData("appId");
    final appKey = await storageController.getData("appKey");
    final base = await storageController.getData("base");

    final tokenUrl = '$base/oauth/token';
    final Map<String, String> body = {
      'grant_type': 'password',
      "client_id": appId,
      "client_secret": appKey,
      "username": username,
      "password": password,
      "scope": ""
    };

    final response = await http.post(
      Uri.parse(tokenUrl),
      body: body,
    );

    if(response.statusCode == 200){
      storageController.storeData("loginPassword", password);
      Map<String, dynamic> data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      await storageController.storeData("accessToken", accessToken);
      await storageController.storeData("mailboxNumber", username);
    }

    return response.statusCode;
  }

  Completer<void> redirect(BuildContext context, Widget pageClassName) {
    Completer<void> completer = Completer<void>();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        completer.complete();
        return pageClassName;
      }),
    );
    return completer;
  }

  Future<PermissionStatus> requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) {
      debugPrint("${permission.toString()} permission is granted...");
    } else if (status.isDenied) {
      debugPrint("${permission.toString()} permission is denied...");
    } else if (status.isPermanentlyDenied) {
      debugPrint("${permission.toString()} permission is permanently denied...");
    }
    return status;
  }
}

final coreController = CoreController();