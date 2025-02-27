
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:meassage_alert/screen/MessageSettingScreen.dart';

import 'package:meassage_alert/utils/database_Helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/call_log_screen.dart';

import 'package:another_telephony/telephony.dart';
import 'package:call_log/call_log.dart';

import 'package:flutter/services.dart';

void startNativeService() {
  const platform = MethodChannel('background_service_channel');

  try {
    platform.invokeMethod('startNativeService');
  } catch (e) {
    print("Error starting native service: $e");
  }
}




Future<void> startBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
     
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Initialize plugins in background context
  WidgetsFlutterBinding.ensureInitialized();
 
  
  final telephony = Telephony.backgroundInstance;
  final DateFormat dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

  

  // Setup periodic check every 15 minutes
  Timer timer = Timer.periodic(const Duration(seconds: 10), (timer) async {

    print("Background Service Running...");
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Missed Call Service",
        content: "Last checked: ${DateTime.now()}",
      );
    }
 
    await _checkMissedCallsAndSendSMS(telephony, dateFormat);
  });

  // Initial immediate check
  await _checkMissedCallsAndSendSMS(telephony, dateFormat);

  service.on('stopService').listen((event) {
    timer.cancel();
    service.stopSelf();
  });
}



Future<void> _checkMissedCallsAndSendSMS(Telephony telephony, DateFormat dateFormat) async {
  print("🟢 Checking for missed calls...");
  
  try {
    final now = DateTime.now();
    final logs = await CallLog.get();
    
    final missedCalls = logs.where((log) {
      if (log.callType != CallType.missed || log.timestamp == null) return false;
      final logDate = DateTime.fromMillisecondsSinceEpoch(log.timestamp!);
      return logDate.year == now.year && 
             logDate.month == now.month && 
             logDate.day == now.day;
    }).toList();

    print("📞 Found ${missedCalls.length} missed calls today");

    for (final call in missedCalls) {
      final number = call.number;
      if (number == null || number.isEmpty) continue;
      
      final time = dateFormat.format(
        DateTime.fromMillisecondsSinceEpoch(call.timestamp!),
      );

      final sent = await MessageLogService.isMessageSent(number, time);
      if (!sent) {
        await _sendSmsToNumber(telephony, number, time);
      }
    }
  } catch (e) {
    print("❌ Error in background task: $e");
  }
}

Future<void> _sendSmsToNumber(Telephony telephony, String number, String time) async {
  try {
    final message = await MessageSettingsScreen.getMessage();
    await telephony.sendSms(to: number, message: message);
    await MessageLogService.logMessage(number, time);

    print("✅ Sent SMS to $number at $time");
  } catch (e) {
    print("❌ Failed to send SMS to $number: $e");
  }
}

Future<void> stopBackgroundService() async {
  final service = FlutterBackgroundService();
  service.invoke('stopService');
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isServiceRunning', false);
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  // iOS background handling
  return true;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await startBackgroundService();
   startNativeService();  // Start Native Foreground Service
   
  MessageLogService().debugPrintMessages(); // Call debugPrintMessages()
  runApp(MaterialApp(home: CallLogScreen(), debugShowCheckedModeBanner: false));
}

