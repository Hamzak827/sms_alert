import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:meassage_alert/utils/database_Helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../screen/today_missed_call_screen.dart';

class CallLogScreen extends StatefulWidget {
  @override
  _CallLogScreenState createState() => _CallLogScreenState();
}

class _CallLogScreenState extends State<CallLogScreen> {
  late Future<List<CallLogEntry>> _missedCalls;
    bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _missedCalls = getMissedCalls();
  }

   Future<void> _checkServiceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isServiceRunning = prefs.getBool('isServiceRunning') ?? false;
    });
  }

//   Future<void> _checkServiceStatus() async {
//   final service = FlutterBackgroundService();
//   bool isRunning = await service.isRunning();
  
//   setState(() {
//     _isServiceRunning = isRunning;
//   });
// }


  Future<void> _toggleService() async {
    final prefs = await SharedPreferences.getInstance();

    if (_isServiceRunning) {
      await stopBackgroundService();
      await prefs.setBool('isServiceRunning', false);
    } else {
      await startBackgroundService();
      await prefs.setBool('isServiceRunning', true);
    }

    setState(() {
      _isServiceRunning = !_isServiceRunning;
    });
  }


  Future<List<CallLogEntry>> getMissedCalls() async {
    try {
      final status = await Permission.phone.request();
      if (!status.isGranted) return [];

      final logs = await CallLog.get();
      return logs.where((log) => log.callType == CallType.missed).toList();
    } catch (e) {
      throw Exception('Failed to fetch missed calls: $e');
    }
  }

  String formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    return DateFormat('MMM dd, yyyy - hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missed Calls History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _missedCalls = getMissedCalls();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TodayMissedCallsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<CallLogEntry>>(
        future: _missedCalls,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No missed calls found!'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final call = snapshot.data![index];
                return ListTile(
                  leading: const Icon(Icons.call_missed, color: Colors.red),
                  title: Text(call.number ?? 'Unknown number'),
                  subtitle: Text(formatTimestamp(call.timestamp)),
                  trailing: Text('${call.duration}s'),
                );
              },
            );
          }
        },
      ),
        floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
      onPressed: () async {
  try {
    await MessageLogService.updateMessage(
  '03082282617',
  'Feb 26, 2025 - 11:29 AM',
  //updatedTimestamp: 'Feb 26, 2025 - 11:31 AM',
   status: 0,
);


     // Fetch and print all saved messages after the update
      final messageLogService = MessageLogService();
      messageLogService.debugPrintMessages();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Call status updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to update status: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
},


        child: const Icon(Icons.send),
        backgroundColor: Colors.blue,
      ),
          const SizedBox(height: 10), // Spacing between buttons
          FloatingActionButton.extended(
            onPressed: _toggleService,
            icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
            label: Text(_isServiceRunning ? "Stop Service" : "Start Service"),
            backgroundColor: _isServiceRunning ? Colors.red : Colors.green,
          ),
        ],
      ),

    );
  }
}

