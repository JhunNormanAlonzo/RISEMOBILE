



import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lecle_volume_flutter/lecle_volume_flutter.dart';

class MyAudio{
  final player = AudioPlayer();
  bool isPlaying = true;

  void playNativeRingtone() async {

  }

  void stopNativeRingtone() async {
    const MethodChannel platform = MethodChannel('com.example.app/ringtone');
    await platform.invokeMethod('stopRingtone');
  }

  Future<void> danger() async {
    await Volume.initAudioStream(AudioManager.streamMusic);
    final maxVol = await Volume.getVol;

    await Volume.setVol(
        androidVol: maxVol.toInt(),
        iOSVol: maxVol.toDouble(),
        showVolumeUI: false
    );

    await player.setAsset('assets/sounds/danger.mp3');
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (isPlaying) { // Check if playback should continue
          player.seek(Duration.zero);
          player.play();
        }
      }
    });
    isPlaying = true;
    await player.play();
  }

 Future<void> incoming() async {
   await Volume.initAudioStream(AudioManager.streamMusic);
   final currentVolume = await Volume.getVol;
   await Volume.setVol(
       androidVol: currentVolume.toInt(),
       iOSVol: currentVolume.toDouble(),
       showVolumeUI: false
   );
    await player.setAsset('assets/sounds/ringing.mp3');
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (isPlaying) { // Check if playback should continue
          player.seek(Duration.zero);
          player.play();
        }
      }
    });
    isPlaying = true;
    await player.play();
  }

  stop() async{
    player.stop();
    isPlaying = false;
  }
}

final myAudio = MyAudio();