import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String baseUrl;
  const ChatScreen({super.key, required this.baseUrl});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': _controller.text});
      _isLoading = true;
    });
    final query = _controller.text;
    _controller.clear();

    try {
      final url = '${widget.baseUrl}/chat_advice/?user_query=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url));
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        _messages.add({'role': 'ai', 'text': data['advice']});
      });
    } catch (e) {
      setState(() => _messages.add({'role': 'ai', 'text': 'Hata: $e'}));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Stil Danışmanı')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (c, i) {
                final isAi = _messages[i]['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAi ? Colors.grey[300] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_messages[i]['text']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Soru sor...'))),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage)
            ]),
          )
        ],
      ),
    );
  }
}