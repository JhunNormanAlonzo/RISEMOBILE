package com.example.rise;

import android.media.Ringtone;
import android.media.RingtoneManager;
import android.net.Uri;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private Ringtone ringtone;


    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.app/ringtone")
                .setMethodCallHandler(
                        (call, result) -> {
                            switch (call.method) {
                                case "playRingtone":
                                    playRingtone();
                                    result.success(null);
                                    break;
                                case "stopRingtone":
                                    stopRingtone();
                                    result.success(null);
                                    break;
                                default:
                                    result.notImplemented();
                                    break;
                            }
                        }
                );
    }

    private void playRingtone() {
        Uri uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM);
        ringtone = RingtoneManager.getRingtone(getApplicationContext(), uri);
        if (ringtone != null) {
            ringtone.play();
        }
    }

    private void stopRingtone() {
        if (ringtone != null && ringtone.isPlaying()) {
            ringtone.stop();
        }
    }
}
