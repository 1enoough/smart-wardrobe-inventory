import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Clothes {
  final int id;
  final String filename;
  final String category;
  final String dominantColor;
  final String season;       // Yeni eklenen alanları da görelim
  final String formality;    // Yeni eklenen alanları da görelim

  Clothes({
    required this.id, 
    required this.filename, 
    required this.category, 
    required this.dominantColor,
    required this.season,
    required this.formality,
  });

  factory Clothes.fromJson(Map<String, dynamic> json) {
    return Clothes(
      id: json['id'],
      filename: json['filename'] ?? '',
      category: json['category'] ?? 'Bilinmiyor',
      dominantColor: json['dominant_color'] ?? '[150,150,150]',
      season: json['season'] ?? '',
      formality: json['formality'] ?? '',
    );
  }
}

class ClothesScreen extends StatefulWidget {
  final String baseUrl;
  const ClothesScreen({super.key, required this.baseUrl});
  @override
  State<ClothesScreen> createState() => _ClothesScreenState();
}

class _ClothesScreenState extends State<ClothesScreen> {
  List<Clothes> _clothes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClothes();
  }

  // String halindeki "[100, 50, 50]" verisini gerçek Flutter Rengine çevirir
  Color _parseColor(String rgbString) {
    try {
      // Köşeli parantezleri ve boşlukları temizle
      String clean = rgbString.replaceAll('[', '').replaceAll(']', '');
      List<String> parts = clean.split(',');
      
      if (parts.length >= 3) {
        int r = int.parse(parts[0].trim());
        int g = int.parse(parts[1].trim());
        int b = int.parse(parts[2].trim());
        return Color.fromARGB(255, r, g, b); // Opaklık %100 (255)
      }
    } catch (e) {
      print("Renk hatası: $e");
    }
    return Colors.grey; // Hata olursa gri göster
  }

  Future<void> _fetchClothes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${widget.baseUrl}/images_colors/'));
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _clothes = data.map((e) => Clothes.fromJson(e)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(int id) async {
    // Silmeden önce onay soralım
    bool confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu kıyafet silinecek."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    await http.delete(Uri.parse('${widget.baseUrl}/delete_clothes/$id'));
    _fetchClothes(); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silindi.'), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dolabım')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _clothes.isEmpty 
          ? const Center(child: Text("Dolabın boş. Hadi bir şeyler yükle!"))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _clothes.length,
              itemBuilder: (context, index) {
                final item = _clothes[index];
                final itemColor = _parseColor(item.dominantColor);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    // SOL TARAFTA RESİM
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${widget.baseUrl}/static/${item.filename}', 
                        width: 60, 
                        height: 60, 
                        fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => const Icon(Icons.error),
                      ),
                    ),
                    
                    // ORTADA BİLGİLER
                    title: Text(
                      item.category, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${item.season} • ${item.formality}'),
                        const SizedBox(height: 6),
                        // RENK KUTUCUĞU BURADA
                        Row(
                          children: [
                            const Text("Tespit Edilen Renk: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: itemColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1))
                                ]
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    
                    // SAĞ TARAFTA SİLME BUTONU
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red), 
                      onPressed: () => _deleteItem(item.id)
                    ),
                  ),
                );
              },
            ),
    );
  }
}