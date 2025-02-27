package com.example.meassage_alert

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class MyForegroundService : Service() {

    private val CHANNEL_ID = "BackgroundServiceChannel"
    private lateinit var methodChannel: MethodChannel

    override fun onCreate() {
        super.onCreate()
        Log.d("Service", "Foreground Service Started")

        // Create Notification Channel
        createNotificationChannel()

        // Start Foreground Service
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Background Service Running")
            .setContentText("Monitoring Missed Calls")
            .setSmallIcon(R.mipmap.ic_launcher) // ✅ Uses default launcher icon

            .build()

        startForeground(1, notification)

        // Initialize Flutter Engine for MethodChannel
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "background_service_channel")

        // Start background logic in Dart
        methodChannel.invokeMethod("startDartBackgroundTask", null)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("Service", "Foreground Service Running")

        // Restart Service if killed
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
