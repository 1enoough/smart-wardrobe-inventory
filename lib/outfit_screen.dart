import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'clothes_screen.dart'; // Clothes sınıfını buradan al

class OutfitScreen extends StatefulWidget {
  final String baseUrl;
  const OutfitScreen({super.key, required this.baseUrl});
  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  String? _season;
  String? _formality;
  List<Clothes> _outfit = [];
  String _msg = 'Seçim yapın';

  Future<void> _getOutfit() async {
    if (_season == null || _formality == null) return;
    setState(() => _msg = 'Aranıyor...');
    try {
      final url = '${widget.baseUrl}/suggest_outfit/?event=$_formality&season=$_season';
      final response = await http.get(Uri.parse(url));
      final List data = json.decode(response.body);
      setState(() {
        _outfit = data.map((e) => Clothes.fromJson(e)).toList();
        _msg = _outfit.isEmpty ? 'Uygun kombin bulunamadı.' : 'Önerilen Kombin:';
      });
    } catch (e) {
      setState(() => _msg = 'Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kombin Önerisi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField(items: ['Yaz', 'Kış', 'Bahar/Güz', 'Dört Mevsim'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => _season = v, decoration: const InputDecoration(labelText: 'Mevsim')),
            DropdownButtonFormField(items: ['Günlük', 'Spor', 'İş', 'Özel Gün'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => _formality = v, decoration: const InputDecoration(labelText: 'Etkinlik')),
            ElevatedButton(onPressed: _getOutfit, child: const Text('Öner')),
            const SizedBox(height: 20),
            Text(_msg, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _outfit.length,
                itemBuilder: (c, i) => ListTile(
                  leading: Image.network('${widget.baseUrl}/static/${_outfit[i].filename}'),
                  title: Text(_outfit[i].category),
                  subtitle: Text(_outfit[i].dominantColor),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}