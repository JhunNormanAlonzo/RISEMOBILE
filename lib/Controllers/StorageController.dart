
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageController{

  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }


  Future<void> storeData(dynamic key, dynamic value) async {
    final prefs = await getPrefs();
    await prefs.setString(key, value);
  }

  Future<dynamic> getData(dynamic key) async {
    final prefs = await getPrefs();
    final value = prefs.getString(key);
    return value ?? '';
  }

  Future<void> removeData(dynamic key) async {
    final prefs = await getPrefs();
    await prefs.remove(key);
  }

  Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("Local storage cleared.");
  }
}

final storageController = StorageController();