import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../utils/database_Helper.dart';
import '../screen/MessageSettingScreen.dart';

class TodayMissedCallsScreen extends StatefulWidget {
  @override
  _TodayMissedCallsScreenState createState() => _TodayMissedCallsScreenState();
}

class _TodayMissedCallsScreenState extends State<TodayMissedCallsScreen> {
  final Telephony _telephony = Telephony.instance;  // SMS sending instance
  List<CallLogEntry> _calls = [];  // List of today's missed calls
  final Map<String, String> _status = {};  // Stores message send statuses for each number
  bool _loading = false;  // Indicates whether the call logs are loading
  bool _isSendingMessages = false;  // Indicates whether messages are being sent

  @override
  void initState() {
    super.initState();
    _loadCalls();
  }

  Future<void> _loadCalls() async {
    setState(() => _loading = true);
    try {
      _calls = await getTodayMissedCalls();
      await _checkAndSendMessages();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<List<CallLogEntry>> getTodayMissedCalls() async {
    try {
      final status = await Permission.phone.request();
      if (!status.isGranted) return [];

      final logs = await CallLog.get();
      final now = DateTime.now();
      return logs.where((log) {
        if (log.callType != CallType.missed || log.timestamp == null) return false;
        final logDate = DateTime.fromMillisecondsSinceEpoch(log.timestamp!);
        return logDate.year == now.year &&
            logDate.month == now.month &&
            logDate.day == now.day;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch today’s missed calls: $e');
    }
  }

  String formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    return DateFormat('MMM dd, yyyy - hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  Future<void> _checkAndSendMessages() async {
    setState(() => _isSendingMessages = true);
    
    try {
      for (final call in _calls.where((c) => c.number != null)) {
        final number = call.number!;
        final time = formatTimestamp(call.timestamp!);
        final sent = await MessageLogService.isMessageSent(number, time);
        
        if (!sent) {
          await _sendSms(call);
        } else {
          _status[number] = 'Sent';
        }
      }
    } finally {
      setState(() => _isSendingMessages = false);
    }
  }

  Future<void> _sendSms(CallLogEntry call) async {
    final number = call.number!;
    final time = formatTimestamp(call.timestamp!);
    
    setState(() => _status[number] = 'Sending...');
    
    try {
      await _telephony.sendSms(
        to: number,
        message: await MessageSettingsScreen.getMessage(),
      );
      await MessageLogService.logMessage(number, time);
      _status[number] = 'Sent';
    } catch (e) {
      _status[number] = 'Not Sent';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Missed Calls"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessageSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_calls.isEmpty)
            const Center(child: Text('No missed calls!'))
          else
            ListView.builder(
              itemCount: _calls.length,
              itemBuilder: (_, i) {
                final call = _calls[i];
                final number = call.number ?? 'Unknown';
                final time = formatTimestamp(call.timestamp!);
                final status = _status[number] ?? 'Not Sent';

                return ListTile(
                  leading: const Icon(Icons.call_missed, color: Colors.red),
                  title: Text(number),
                  subtitle: Text(time),
                  trailing: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Sent'
                          ? Colors.green
                          : status == 'Sending...'
                              ? Colors.blue
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          if (_isSendingMessages)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
