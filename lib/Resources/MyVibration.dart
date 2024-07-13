
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:vibration/vibration.dart';

class MyVibration {
    int pauseDuration = 150;
    int vibrationDuration = 1000;
    int totalDuration = 3600;
    int elapsedTime = 0;
    int deponggol = 1000;
  void start() async {
    elapsedTime = 0;
    resetTotalDuration();
    while (elapsedTime < totalDuration) {
      Vibration.vibrate(duration: vibrationDuration);
      await Future.delayed(Duration(milliseconds: vibrationDuration + pauseDuration));
      elapsedTime++;
      debugPrint("elapsedTime : $elapsedTime");
      debugPrint("totalDuration : $totalDuration");
    }
  }

  void resetTotalDuration(){
    totalDuration = 3600;
  }

   void stop() {
    Vibration.cancel();
    totalDuration = elapsedTime;
  }


    void stopVibration() {
      FlutterBackgroundService().invoke("stopVibration");
    }

}

final vibrator = MyVibration();

