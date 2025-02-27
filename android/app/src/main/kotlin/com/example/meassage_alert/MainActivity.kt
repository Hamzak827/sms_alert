package com.example.meassage_alert
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel





class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.meassage_alert/service"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, MyForegroundService::class.java)
                    startForegroundService(intent)
                    result.success("Service Started")
                }
                "stopService" -> {
                    val intent = Intent(this, MyForegroundService::class.java)
                    stopService(intent)
                    result.success("Service Stopped")
                }
                else -> result.notImplemented()
            }
        }
    }
}
