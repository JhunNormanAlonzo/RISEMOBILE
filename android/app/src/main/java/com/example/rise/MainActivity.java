package com.example.rise;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.app.Person;
import android.widget.Toast;
import android.telecom.Call;
import android.media.Ringtone;
import android.content.Intent;
import android.content.Context;
import android.app.Notification;
import android.app.PendingIntent;
import android.provider.Settings;
import androidx.annotation.NonNull;
import android.media.RingtoneManager;
import androidx.annotation.RequiresApi;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import io.flutter.plugin.common.MethodCall;
import androidx.core.app.NotificationCompat;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterActivity;
import com.cloudwebrtc.webrtc.record.AudioTrackInterceptor;




public class MainActivity extends FlutterActivity {
    private Ringtone ringtone;
    private AudioTrackInterceptor audioTrackInterceptor;
    private static final String CHANNEL_ID = "call_id";

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


        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.app/audiotrack")
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("stopAudioTrack")) {
                                stopAudioTrack();
                                result.success(null);
                            } else {
                                result.notImplemented();
                            }
                        }
                );

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.app/background_service")
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("requestIgnoreBatteryOptimizations")) {
                                boolean isIgnoringBatteryOptimizations = requestIgnoreBatteryOptimizations();
                                result.success(isIgnoringBatteryOptimizations);
                            } else {
                                result.notImplemented();
                            }
                        }
                );

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.app/notification")
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("showFireAlarm")) {
                                String title = call.argument("title");
                                String message = call.argument("message");
                                showFireAlarm(title, message);
                                result.success(null);
                            } else {
                                result.notImplemented();
                            }
                        }
                );

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.app/call_notification")
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("sendIncomingCall")) {
                                String extension = call.argument("extension");
                                Person caller = new Person.Builder()
                                        .setName("Unknown Caller")  // Default or generic name for the caller
                                        .build();
                                NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

                                // Create Notification Channel for Android O and above
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    NotificationChannel channel = new NotificationChannel(
                                            "call_notification_channel",
                                            "Call Notifications",
                                            NotificationManager.IMPORTANCE_HIGH
                                    );
                                    notificationManager.createNotificationChannel(channel);
                                }

                                // Set up pending intents for answer/decline actions
                                PendingIntent answerIntent = PendingIntent.getActivity(
                                        getApplicationContext(),
                                        0,
                                        new Intent(),
                                        PendingIntent.FLAG_IMMUTABLE
                                );

                                PendingIntent declineIntent = PendingIntent.getActivity(
                                        getApplicationContext(),
                                        0,
                                        new Intent(),
                                        PendingIntent.FLAG_IMMUTABLE
                                );

                                // Build CallStyle Notification (requires API 31 or higher)
                                Notification notification = new Notification.Builder(getApplicationContext(), "call_notification_channel")
                                        .setSmallIcon(R.drawable.ic_notification)  // Replace with your app's icon
                                        .setContentTitle("Incoming Call")
                                        .setContentText("Caller: " + extension)
                                        .setOngoing(true)  // Make the notification non-dismissible
                                        .setStyle(Notification.CallStyle.forIncomingCall(
                                                caller,
                                                declineIntent,
                                                answerIntent
                                        ))
                                        .setAutoCancel(false)  // Do not allow the notification to auto-dismiss
                                        .build();

                                // Set FLAG_ONGOING_EVENT to prevent dismissal
                                notification.flags |= Notification.FLAG_ONGOING_EVENT;

                                // Show the notification
                                notificationManager.notify(1, notification);

                                result.success(null);
                            } else {
                                result.notImplemented();
                            }
                        }
                );

    }




    private void showIncomingCallNotification(String extension) {
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        // Create notification channel for Android 8.0 (API level 26) and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Call Notifications",
                    NotificationManager.IMPORTANCE_HIGH
            );
            notificationManager.createNotificationChannel(channel);
        }

        // Create an intent to open the app when the notification is clicked
        Intent intent = new Intent(this, MainActivity.class);
        PendingIntent contentIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        // Build the notification
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Incoming Call")
                .setContentText("Extension: " + extension)
                .setSmallIcon(R.drawable.ic_notification)  // Ensure this resource exists
                .setContentIntent(contentIntent)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(false);  // Do not auto-cancel the notification

        notificationManager.notify(1, builder.build());
    }
    private void showFireAlarm(String title, String message) {
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        // Create notification channel for Android 8.0 (API level 26) and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    "fire_alarm_id",
                    "Notification Channel",
                    NotificationManager.IMPORTANCE_HIGH
            );
            notificationManager.createNotificationChannel(channel);
        }

        // Build the notification
        // Intent to open MainActivity when notification is clicked
        Intent intent = new Intent(this, MainActivity.class);
        intent.putExtra("notification_title", title);  // Pass extra data if needed
        intent.putExtra("notification_message", message);  // Pass extra data if needed
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        // Build the notification
        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(this, "fire_alarm_id")
                .setContentTitle(title)
                .setContentText(message)
                .setContentIntent(pendingIntent)
                .setSmallIcon(R.drawable.ic_notification)
                .setAutoCancel(false)
                .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
                .setVibrate(new long[] {1000, 1000, 1000, 1000, 1000})
                .setPriority(NotificationCompat.PRIORITY_HIGH);

        // Show the notification
        notificationManager.notify(1, notificationBuilder.build());
    }
    private boolean requestIgnoreBatteryOptimizations() {
        Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
        intent.setData(Uri.parse("package:" + getPackageName()));
        startActivity(intent);
        return true;
    }

    private void playRingtone() {
        Uri uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM);
        ringtone = RingtoneManager.getRingtone(getApplicationContext(), uri);
        if (ringtone != null) {
            ringtone.play();
        }
    }

    private void stopAudioTrack() {
        audioTrackInterceptor.stop();
    }
    private void stopRingtone() {
        if (ringtone != null && ringtone.isPlaying()) {
            ringtone.stop();
        }
    }
}
