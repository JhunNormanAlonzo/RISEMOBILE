
import 'package:flutter_background_service/flutter_background_service.dart';

class NativeRingtone {

  void playRingtone() {
    FlutterBackgroundService().invoke("playRingtone");
  }

  void stopRingtone() {
    FlutterBackgroundService().invoke("stopRingtone");
  }

}