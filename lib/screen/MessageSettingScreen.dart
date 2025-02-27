import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageSettingsScreen extends StatefulWidget {
  static Future<String> getMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('message') ?? 'You missed my call';
  }

  @override
  _MessageSettingsScreenState createState() => _MessageSettingsScreenState();
}

class _MessageSettingsScreenState extends State<MessageSettingsScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  Future<void> _loadMessage() async {
    _controller.text = await MessageSettingsScreen.getMessage();
    setState(() {});
  }

  Future<void> _saveMessage() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('message', _controller.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message saved!')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Auto-response message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _saveMessage,
              child: _saving 
                  ? const CircularProgressIndicator()
                  : const Text('Save Message'),
            ),
          ],
        ),
      ),
    );
  }
}