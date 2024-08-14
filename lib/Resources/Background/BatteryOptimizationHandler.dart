import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationHandler {
  static const platform = MethodChannel('com.example.app/background_service');

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      final bool result = await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      if (result) {
        print("Battery optimization ignored");
      } else {
        print("Battery optimization not ignored");
      }
    } on PlatformException catch (e) {
      print("Failed to request battery optimization ignore: ${e.message}");
    }
  }

  static Future<void> requestPermissions() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }

    // Now request battery optimizations ignore
    await requestIgnoreBatteryOptimizations();
  }
}
