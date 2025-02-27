package com.example.meassage_alert

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class RestartServiceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d("Receiver", "Restarting Background Service...")
        context?.startService(Intent(context, MyForegroundService::class.java))
    }
}
