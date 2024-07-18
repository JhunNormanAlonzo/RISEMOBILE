

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_encrypt_plus/flutter_encrypt_plus.dart';
import 'package:http/http.dart' as http;
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/GeneralConfiguration.dart';
import 'package:rise/Resources/MyToast.dart';

class ApiController{

  var _accessToken = '';
  var _base = '';
  ApiController() {
    Future.microtask(() async {
      final accessToken = await storageController.getData("accessToken");
      final base = await storageController.getData("base");
      _accessToken = accessToken;
      _base = base;
    });
  }


  Future<String?> getAndroidHost() async {

      var androidHost = await storageController.getData("androidHost");
      debugPrint("android host $androidHost");
      if (androidHost == null || androidHost.isEmpty) {
        debugPrint("Getting data to server instead of local storage.");
        final base = await storageController.getData("base");
        final route = "$base/api/mobile/android_host";
        debugPrint("route : $route");
        final response = await http.get(
            Uri.parse(route), headers: await getHeaders());
        androidHost = response.body;
        await storageController.storeData("androidHost", androidHost);
      }
      return androidHost;
  }

  //Storing needed user data to local storage.
  Future<dynamic> getUserData() async {
    final mailboxNumber = await storageController.getData("mailboxNumber");
    final loginPassword = await storageController.getData("loginPassword");
    debugPrint("mailbox : $mailboxNumber");
    debugPrint("login password : $loginPassword");
    final base = await storageController.getData("base");
    final route = "$base/api/mobile/user_data/$mailboxNumber/$loginPassword";
    debugPrint("route : $route");
    final response = await http.get(Uri.parse(route), headers: await getHeaders());
    final userData = response.body;

    Map<String, dynamic> parsedJson = jsonDecode(userData);

    final password = encrypt.decodeString(parsedJson['mailbox']['password'], GeneralConfiguration().getSalt);
    await storageController.storeData("password", password);
    debugPrint("user data start");
    debugPrint(password);
    debugPrint("user data end");
  }

  // Future<Map<String, dynamic>>getUserData(username, password) async{
  //   final base = await storageController.getData("base");
  //   final route = "$base/api/mobile/user_data/$username/$password";
  //   final response = await http.get(Uri.parse(route), headers: await getHeaders());
  //   Map<String, dynamic> data = jsonDecode(response.body);
  //   return data;
  // }


  Future<Map<String, dynamic>>getMe() async {
    final base = await storageController.getData("base");
    final route = "$base/api/me";
    final response = await http.get(Uri.parse(route), headers: await getHeaders());
    Map<String, dynamic> data = jsonDecode(response.body);
    if (data['user']?['mailbox'] != null) {
      final mailboxNumber = data['user']['mailbox']['mailbox_number'];
      storageController.storeData("mailboxNumber", mailboxNumber);
      debugPrint('Mailbox number: $mailboxNumber');
    }
    return data;
  }


  Future<String> getAccessToken() async {
    final accessToken = await storageController.getData('accessToken');
    return accessToken ?? '';
  }

  Future<Map<String, String>> getHeaders() async{
    final accessToken = await getAccessToken();
    final dynamic headers =  {
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    return headers;
  }






}

final api = ApiController();