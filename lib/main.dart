import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

// ==========================================
// TEMA VE UYGULAMA AYARLARI
// ==========================================
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vogue Wardrobe',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        cardColor: Color(0xFF1C1C1E),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      home: MainScreen(),
    );
  }
}

// ==========================================
// ANA ÇERÇEVE
// ==========================================
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    DashboardPage(), 
    ClosetPage(key: PageStorageKey('closet')),    
    StylistPage(),   
  ];

  void _refreshCloset() {
    ClosetPage.refreshStream.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade700,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 28), label: "Ana Sayfa"),
            BottomNavigationBarItem(icon: Icon(Icons.checkroom, size: 28), label: "Dolabım"),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome, size: 28), label: "Stilist"),
          ],
        ),
      ),
      
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: Colors.black, size: 30),
        onPressed: () async {
          final result = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => UploadModal(),
          );

          if (result == true) {
            _refreshCloset();
          }
        },
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ==========================================
// 1. SAYFA: DASHBOARD
// ==========================================
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  String userName = "Misafir"; 
  String userCity = "Şehir Seçilmedi";
  String weatherCondition = "Bulutlu"; 
  String temperature = "--°";
  bool isDayTime = true; 

  late AnimationController _fxController;
  List<RainDrop> rainDrops = [];
  List<SnowFlake> snowFlakes = [];
  List<Star> stars = [];
  List<Cloud> clouds = [];
  ShootingStar? activeShootingStar;
  final Random random = Random();
  
  final String apiUrl = "http://127.0.0.1:8000";
  List<dynamic> recentClothes = [];

  @override
  void initState() {
    super.initState();
    fetchRecentClothes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingDialog();
    });
    _fxController = AnimationController(vsync: this, duration: Duration(seconds: 1))..repeat();
    _fxController.addListener(_updatePhysics);
    _initParticles();
  }

  void _initParticles() {
    rainDrops.clear(); snowFlakes.clear(); stars.clear(); clouds.clear();
    for (int i = 0; i < 150; i++) rainDrops.add(RainDrop(x: random.nextDouble(), y: random.nextDouble(), z: random.nextDouble() * 0.5 + 0.5, speed: 0.02 + random.nextDouble() * 0.03));
    for (int i = 0; i < 80; i++) snowFlakes.add(SnowFlake(x: random.nextDouble(), y: random.nextDouble(), size: random.nextDouble() * 3 + 2, speed: 0.002 + random.nextDouble() * 0.005, wobble: random.nextDouble() * 2 * pi));
    for (int i = 0; i < 60; i++) stars.add(Star(x: random.nextDouble(), y: random.nextDouble(), size: random.nextDouble() * 1.5 + 0.5, brightness: random.nextDouble()));
    for (int i = 0; i < 6; i++) clouds.add(Cloud(x: random.nextDouble(), y: random.nextDouble() * 0.3, speed: 0.0002 + random.nextDouble() * 0.0005, size: 0.15 + random.nextDouble() * 0.2, opacity: 0.3 + random.nextDouble() * 0.4));
  }

  void _updatePhysics() {
    setState(() {
      if (weatherCondition == "Yagmur") {
        for (var drop in rainDrops) { drop.y += drop.speed * drop.z; if (drop.y > 1.0) { drop.y = -0.1; drop.x = random.nextDouble(); } }
      }
      if (weatherCondition == "Kar") {
        for (var flake in snowFlakes) { flake.y += flake.speed; flake.wobble += 0.05; flake.x += sin(flake.wobble) * 0.002; if (flake.y > 1.0) { flake.y = -0.1; flake.x = random.nextDouble(); } }
      }
      if (["Bulutlu", "Yagmur", "Kar"].contains(weatherCondition)) {
        for (var cloud in clouds) { cloud.x += cloud.speed; if (cloud.x > 1.4) { cloud.x = -0.4; cloud.y = random.nextDouble() * 0.4; } }
      }
      if (!isDayTime && weatherCondition == "Gunes") {
        if (activeShootingStar == null) { if (random.nextDouble() < 0.008) activeShootingStar = ShootingStar(x: random.nextDouble(), y: random.nextDouble() * 0.4, dx: 0.03, dy: 0.015, life: 1.0); } 
        else { activeShootingStar!.x += activeShootingStar!.dx; activeShootingStar!.y += activeShootingStar!.dy; activeShootingStar!.life -= 0.03; if (activeShootingStar!.life <= 0) activeShootingStar = null; }
      }
    });
  }

  @override
  void dispose() { _fxController.dispose(); super.dispose(); }

  Future<void> _fetchWeatherByCityName(String city) async {
    try {
      final geoUrl = Uri.parse("https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=tr&format=json");
      final geoResp = await http.get(geoUrl);
      if (geoResp.statusCode == 200) {
        var geoData = json.decode(geoResp.body);
        if (geoData['results'] != null && geoData['results'].length > 0) {
          double lat = geoData['results'][0]['latitude'];
          double lon = geoData['results'][0]['longitude'];
          String realCityName = geoData['results'][0]['name'];
          final weatherUrl = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
          final wResp = await http.get(weatherUrl);
          if (wResp.statusCode == 200) {
            var current = json.decode(wResp.body)['current_weather'];
            int code = current['weathercode'];
            int isDay = current['is_day'];
            setState(() {
              userCity = realCityName; temperature = "${current['temperature'].round()}°"; isDayTime = (isDay == 1);
              if ([71,73,75,77,85,86].contains(code)) weatherCondition = "Kar";
              else if (code >= 51 && code <= 67 || code >= 80 && code <= 82 || code >= 95) weatherCondition = "Yagmur";
              else if (code <= 2) weatherCondition = "Gunes";
              else weatherCondition = "Bulutlu";
            });
          }
        }
      }
    } catch (e) { print(e); }
  }

  Future<void> fetchRecentClothes() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/images_colors/'));
      if (response.statusCode == 200) {
        setState(() { recentClothes = json.decode(utf8.decode(response.bodyBytes)).reversed.take(5).toList(); });
      }
    } catch (e) { print(e); }
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return "Günaydın,";
    if (hour >= 12 && hour < 17) return "İyi Günler,";
    if (hour >= 17 && hour < 23) return "İyi Akşamlar,";
    return "İyi Geceler,";
  }

  // --- METİNLER ---
  String getHeroTitle() {
    int tempValue = int.tryParse(temperature.replaceAll('°', '').trim()) ?? 20;
    if (tempValue < 12) return "Soğuklara Dikkat";
    if (weatherCondition == "Yagmur") return "Yağmura Hazırlan";
    if (weatherCondition == "Kar") return "Kar Stili";
    if (!isDayTime) return "Gece Şıklığı";
    if (weatherCondition == "Gunes") return "Güneşin Tadını Çıkar";
    return "Bulutlu ve Rahat";
  }

  String getHeroSubtitle() {
    int tempValue = int.tryParse(temperature.replaceAll('°', '').trim()) ?? 20;
    if (tempValue < 12) return "Kaban • Kazak • Bot";
    if (tempValue >= 12 && tempValue < 19) return "Hırka • Jean • Sneaker";
    if (weatherCondition == "Yagmur") return "Trençkot • Bot • Şemsiye";
    if (weatherCondition == "Kar") return "Kaban • Atkı • Eldiven";
    if (!isDayTime) return "Ceket • Koyu Jean • Deri";
    if (weatherCondition == "Gunes") return "Tişört • Şort • Gözlük";
    return "Sweatshirt • Jean • Sneaker";
  }

  void _showOnboardingDialog() {
    TextEditingController nameCtrl = TextEditingController(); TextEditingController cityCtrl = TextEditingController();
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(title: Text("Hoş Geldiniz", style: TextStyle(color: Colors.white), textAlign: TextAlign.center), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Adınız")), SizedBox(height: 10), TextField(controller: cityCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Şehir"))]), actions: [ElevatedButton(onPressed: () { if(nameCtrl.text.isNotEmpty && cityCtrl.text.isNotEmpty) { setState(() { userName = nameCtrl.text; userCity = cityCtrl.text; }); Navigator.pop(ctx); _fetchWeatherByCityName(userCity); }}, child: Text("Başla"))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildWeatherBackground(),
          CustomPaint(
            painter: CinematicWeatherPainter(rainDrops: weatherCondition == "Yagmur" ? rainDrops : [], snowFlakes: weatherCondition == "Kar" ? snowFlakes : [], stars: (!isDayTime && (weatherCondition == "Gunes" || weatherCondition == "Gece")) ? stars : [], clouds: (weatherCondition != "Gunes" && weatherCondition != "Gece") ? clouds : [], shootingStar: activeShootingStar, isDay: isDayTime),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.all(24.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [GestureDetector(onTap: _showOnboardingDialog, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(getGreeting(), style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1)), Text(userName, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))])), Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)), child: Row(children: [Icon(weatherCondition == "Yagmur" ? Icons.water_drop : weatherCondition == "Kar" ? Icons.ac_unit : isDayTime ? Icons.wb_sunny : Icons.nights_stay, color: Colors.white, size: 20), SizedBox(width: 8), Text("$temperature $userCity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))])),
                  
                  // HERO KART (MANKEN RESMİ KALDIRILDI)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    height: 200, 
                    width: double.infinity, 
                    decoration: BoxDecoration(
                      // Resim yerine şık bir gradient koyuyoruz
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight
                      ),
                      borderRadius: BorderRadius.circular(25), 
                      border: Border.all(color: Colors.white10),
                    ), 
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: Text("GÜNÜN ÖZETİ", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))), 
                          SizedBox(height: 15), 
                          Text(getHeroTitle(), style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), 
                          SizedBox(height: 10), 
                          Text(getHeroSubtitle(), style: TextStyle(color: Colors.white70, fontSize: 16))
                        ]
                      ),
                    )
                  ),
                  
                  SizedBox(height: 30),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("SON EKLENENLER", style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold)), Icon(Icons.arrow_forward, color: Colors.white30, size: 18)])),
                  SizedBox(height: 15),
                  Container(height: 140, child: recentClothes.isEmpty ? Center(child: Text("Henüz parça yok.", style: TextStyle(color: Colors.white54))) : ListView.builder(padding: EdgeInsets.symmetric(horizontal: 24), scrollDirection: Axis.horizontal, itemCount: recentClothes.length, itemBuilder: (context, index) { var item = recentClothes[index]; return Container(width: 100, margin: EdgeInsets.only(right: 15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(8.0), child: Image.network("$apiUrl/static/${item['filename']}", fit: BoxFit.contain))), Expanded(flex: 1, child: Text(item['category'], style: TextStyle(color: Colors.white70, fontSize: 10), overflow: TextOverflow.ellipsis))])); }))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherBackground() {
    List<Color> colors;
    if (weatherCondition == "Yagmur") colors = [Color(0xFF203A43), Color(0xFF2C5364)];
    else if (weatherCondition == "Kar") colors = [Color(0xFF83a4d4), Color(0xFFb6fbff)];
    else if (!isDayTime) colors = [Color(0xFF0f2027), Color(0xFF203a43)];
    else if (weatherCondition == "Bulutlu") colors = [Color(0xFF606c88), Color(0xFF3f4c6b)];
    else colors = [Color(0xFF2980B9), Color(0xFF6DD5FA)];
    return Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)));
  }
}

// Efekt Sınıfları
class RainDrop { double x, y, z, speed; RainDrop({required this.x, required this.y, required this.z, required this.speed}); }
class SnowFlake { double x, y, size, speed, wobble; SnowFlake({required this.x, required this.y, required this.size, required this.speed, required this.wobble}); }
class Star { double x, y, size, brightness; Star({required this.x, required this.y, required this.size, required this.brightness}); }
class Cloud { double x, y, speed, size, opacity; Cloud({required this.x, required this.y, required this.speed, required this.size, required this.opacity}); }
class ShootingStar { double x, y, dx, dy, life; ShootingStar({required this.x, required this.y, required this.dx, required this.dy, required this.life}); }
class CinematicWeatherPainter extends CustomPainter {
  final List<RainDrop> rainDrops; final List<SnowFlake> snowFlakes; final List<Star> stars; final List<Cloud> clouds; final ShootingStar? shootingStar; final bool isDay;
  CinematicWeatherPainter({required this.rainDrops, required this.snowFlakes, required this.stars, required this.clouds, this.shootingStar, required this.isDay});
  @override void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white; for (var star in stars) { starPaint.color = Colors.white.withOpacity(star.brightness); canvas.drawCircle(Offset(star.x * size.width, star.y * size.height * 0.7), star.size, starPaint); }
    if (shootingStar != null) { final shootPaint = Paint()..color = Colors.white.withOpacity(shootingStar!.life)..strokeWidth = 2..strokeCap = StrokeCap.round; double sx = shootingStar!.x * size.width; double sy = shootingStar!.y * size.height; canvas.drawLine(Offset(sx, sy), Offset(sx - 40, sy - 20), shootPaint); }
    final cloudPaint = Paint(); for (var cloud in clouds) { cloudPaint.color = isDay ? Colors.white.withOpacity(cloud.opacity) : Colors.grey.shade400.withOpacity(cloud.opacity * 0.5); cloudPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 30); double cx = cloud.x * size.width; double cy = cloud.y * size.height; double r = cloud.size * size.width; canvas.drawCircle(Offset(cx, cy), r, cloudPaint); canvas.drawCircle(Offset(cx + r*0.6, cy - r*0.2), r*0.8, cloudPaint); }
    final rainPaint = Paint()..strokeCap = StrokeCap.round; for (var drop in rainDrops) { rainPaint.color = Colors.white.withOpacity(drop.z * 0.4); rainPaint.strokeWidth = drop.z * 2; double dx = drop.x * size.width; double dy = drop.y * size.height; double len = 20 * drop.z; canvas.drawLine(Offset(dx, dy), Offset(dx - 5, dy + len), rainPaint); }
    final snowPaint = Paint()..color = Colors.white; for (var flake in snowFlakes) { snowPaint.color = Colors.white.withOpacity(0.8); canvas.drawCircle(Offset(flake.x * size.width, flake.y * size.height), flake.size / 2, snowPaint); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 2. SAYFA: GARDIROBUM
// ==========================================
class ClosetPage extends StatefulWidget {
  static final refreshStream = ValueNotifier<bool>(false);

  const ClosetPage({Key? key}) : super(key: key);

  @override
  _ClosetPageState createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  final String apiUrl = "http://127.0.0.1:8000";
  List<dynamic> allClothes = [];
  List<dynamic> filteredClothes = [];
  bool isLoading = true;

  final List<String> categories = ["Tümü", "Üst Giyim", "Alt Giyim", "Dış Giyim", "Ayakkabı", "Aksesuar"];
  String selectedCategory = "Tümü";

  final Map<String, List<int>> colorMap = {
    'Siyah': [0, 0, 0],
    'Beyaz': [255, 255, 255],
    'Gri': [128, 128, 128],
    'Kırmızı': [255, 0, 0],
    'Bordo': [128, 0, 0],
    'Yeşil': [0, 128, 0],
    'Haki': [107, 142, 35],
    'Mavi': [0, 0, 255],
    'Lacivert': [0, 0, 128],
    'Sarı': [255, 255, 0],
    'Turuncu': [255, 165, 0],
    'Mor': [128, 0, 128],
    'Pembe': [255, 192, 203],
    'Kahverengi': [165, 42, 42],
    'Bej': [245, 245, 220],
    'Krem': [255, 253, 208],
  };

  @override
  void initState() {
    super.initState();
    fetchClothes();
    ClosetPage.refreshStream.addListener(() {
      if (ClosetPage.refreshStream.value) {
        fetchClothes();
        ClosetPage.refreshStream.value = false;
      }
    });
  }

  Future<void> fetchClothes() async {
    setState(() { isLoading = true; });
    try {
      final response = await http.get(Uri.parse('$apiUrl/images_colors/'));
      if (response.statusCode == 200) {
        var data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          allClothes = data;
          _filterClothes(); 
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  void _filterClothes() {
    if (selectedCategory == "Tümü") {
      filteredClothes = List.from(allClothes);
    } else {
      filteredClothes = allClothes.where((item) {
        String cat = item['category'].toString().toLowerCase();
        if (selectedCategory == "Üst Giyim") return cat.contains("shirt") || cat.contains("top") || cat.contains("üst") || cat.contains("kazak") || cat.contains("gömlek") || cat.contains("sweat");
        if (selectedCategory == "Alt Giyim") return cat.contains("pant") || cat.contains("jean") || cat.contains("etek") || cat.contains("şort");
        if (selectedCategory == "Dış Giyim") return cat.contains("coat") || cat.contains("jacket") || cat.contains("mont") || cat.contains("kaban");
        if (selectedCategory == "Ayakkabı") return cat.contains("shoe") || cat.contains("boot") || cat.contains("sneaker") || cat.contains("terlik");
        return cat.contains(selectedCategory.toLowerCase());
      }).toList();
    }
  }

  String _parseColor(dynamic colorData) {
    List<int> rgb = [];

    try {
      if (colorData is String) {
        String cleanData = colorData.replaceAll('[', '').replaceAll(']', '');
        if (cleanData.isNotEmpty) {
          rgb = cleanData.split(',').map((e) => double.parse(e.trim()).round()).toList();
        }
      } else if (colorData is List) {
        rgb = colorData.map((e) => int.parse(e.toString())).toList();
      }
    } catch (e) {
      return "Hata";
    }

    if (rgb.length >= 3) {
      int r = rgb[0];
      int g = rgb[1];
      int b = rgb[2];

      if (r > 160 && g > 160 && b > 160) {
        if ((r-g).abs() < 30 && (r-b).abs() < 30) return "Beyaz";
      }
      if (r < 60 && g < 60 && b < 60) return "Siyah";
      if (r > 140 && g < 100 && b < 100) return "Kırmızı";
      if (b > 150 && r < 100 && g < 100) return "Mavi";

      String closestColorName = "Bilinmiyor";
      double minDistance = double.infinity;

      colorMap.forEach((name, mapRgb) {
        double distance = pow(r - mapRgb[0], 2) + pow(g - mapRgb[1], 2) + pow(b - mapRgb[2], 2).toDouble();
        if (distance < minDistance) {
          minDistance = distance;
          closestColorName = name;
        }
      });
      return closestColorName;
    }
    
    return "Belirsiz";
  }

  Future<void> deleteItem(int id) async {
    await http.delete(Uri.parse('$apiUrl/delete_clothes/$id'));
    Navigator.pop(context); 
    fetchClothes(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("KOLEKSİYONUM", style: TextStyle(letterSpacing: 3, fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = categories[index] == selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = categories[index];
                      _filterClothes();
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.white24)
                    ),
                    child: Center(
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : filteredClothes.isEmpty
                    ? Center(child: Text("Bu kategoride parça yok.", style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 100),
                        itemCount: filteredClothes.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          var item = filteredClothes[index];
                          return GestureDetector(
                            onTap: () => _showDetailModal(item), 
                            child: Container(
                              decoration: BoxDecoration(color: Color(0xFF161616), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                      child: Image.network("$apiUrl/static/${item['filename']}", fit: BoxFit.contain),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))),
                                      child: Text(item['category'].toUpperCase(), style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(dynamic item) {
    var rawColor = item['color'] ?? item['dominant_color'];
    String colorName = _parseColor(rawColor); 

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10)))),
              SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.all(20),
                    child: Image.network("$apiUrl/static/${item['filename']}", fit: BoxFit.contain),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['category'].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("Mevsim: ${item['season']}", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(10)),
                    child: Text("Renk: $colorName", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                      showDialog(context: context, builder: (c) => AlertDialog(
                        backgroundColor: Color(0xFF2C2C2E),
                        title: Text("Emin misin?", style: TextStyle(color: Colors.white)),
                        content: Text("Bu parça silinecek.", style: TextStyle(color: Colors.grey)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c), child: Text("İptal")),
                          TextButton(onPressed: () { Navigator.pop(c); deleteItem(item['id']); }, child: Text("Sil", style: TextStyle(color: Colors.red))),
                        ],
                      ));
                  },
                  icon: Icon(Icons.delete_outline),
                  label: Text("DOLAPTAN ÇIKAR"),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 3. SAYFA: STİLİST (KOMBİN)
// ==========================================
class StylistPage extends StatefulWidget {
  @override
  _StylistPageState createState() => _StylistPageState();
}

class _StylistPageState extends State<StylistPage> {
  final String apiUrl = "http://127.0.0.1:8000";
  List<dynamic> outfit = [];
  bool isLoading = false;
  String selectedEvent = "Günlük";
  String selectedSeason = "Yaz";

  Future<void> getOutfit() async {
    setState(() { isLoading = true; outfit = []; });
    try {
      final response = await http.get(Uri.parse('$apiUrl/suggest_outfit/?event=$selectedEvent&season=$selectedSeason'));
      if (response.statusCode == 200) {
        setState(() {
          outfit = json.decode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (e) { print(e); } finally { setState(() { isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("AI STUDIO", style: TextStyle(letterSpacing: 2)), centerTitle: true, backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            color: Color(0xFF1C1C1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip("Mevsim: $selectedSeason", () => setState(() { selectedSeason = selectedSeason == "Yaz" ? "Kış" : selectedSeason == "Kış" ? "Bahar/Güz" : "Yaz"; })),
                _buildFilterChip("Tarz: $selectedEvent", () => setState(() { selectedEvent = selectedEvent == "Günlük" ? "İş" : selectedEvent == "İş" ? "Özel Gün" : "Günlük"; })),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : outfit.isEmpty
                    ? Center(child: Opacity(opacity: 0.3, child: Icon(Icons.checkroom, size: 100, color: Colors.white)))
                    : ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: outfit.length,
                        itemBuilder: (context, index) {
                          var item = outfit[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 20),
                            height: 150,
                            decoration: BoxDecoration(color: Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                            child: Row(
                              children: [
                                Container(
                                  width: 140,
                                  margin: EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage("$apiUrl/static/${item['filename']}"), fit: BoxFit.contain)),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['category'], style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 5),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(5)),
                                        child: Text("Mükemmel Uyum", style: TextStyle(color: Colors.white, fontSize: 10)),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: getOutfit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: StadiumBorder()),
                child: Text("KOMBİN OLUŞTUR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ),
          SizedBox(height: 60)
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(30)),
        child: Text(text, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ==========================================
// 4. UPLOAD MODAL
// ==========================================
class UploadModal extends StatefulWidget {
  @override
  _UploadModalState createState() => _UploadModalState();
}

class _UploadModalState extends State<UploadModal> {
  XFile? _selectedImage;
  bool isUploading = false;
  final picker = ImagePicker();
  final String apiUrl = "http://127.0.0.1:8000";

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() { _selectedImage = pickedFile; });
    }
  }

  Future<void> uploadImage() async {
    if (_selectedImage == null) return;
    setState(() { isUploading = true; });

    var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/upload_clothes/'));

    if (kIsWeb) {
      var bytes = await _selectedImage!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('files', bytes, filename: _selectedImage!.name));
    } else {
      request.files.add(await http.MultipartFile.fromPath('files', _selectedImage!.path));
    }

    try {
      var response = await request.send();
      
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final body = json.decode(respStr);

        List<dynamic> colorList = json.decode(body['detected_color']); 
        Color displayColor = Color.fromRGBO(colorList[0], colorList[1], colorList[2], 1);

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Analiz Tamamlandı ✨", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, 
                  height: 80, 
                  decoration: BoxDecoration(
                    color: displayColor, 
                    shape: BoxShape.circle, 
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: displayColor.withOpacity(0.5), blurRadius: 20)]
                  )
                ),
                SizedBox(height: 20),
                Divider(color: Colors.white24),
                SizedBox(height: 10),
                _buildInfoRow("Kategori", body['detected_category']),
                _buildInfoRow("Mevsim", body['detected_season']),
                _buildInfoRow("Resmiyet", body['detected_formality']),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  child: Text("HARİKA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), 
                  onPressed: () => Navigator.pop(ctx)
                ),
              )
            ]
          )
        );

        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dolabına eklendi!"), backgroundColor: Colors.white, behavior: SnackBarBehavior.floating));
      }
    } catch (e) { 
      print("Hata: $e"); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bir hata oluştu."), backgroundColor: Colors.red));
    } finally { 
      setState(() { isUploading = false; }); 
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(30)), border: Border(top: BorderSide(color: Colors.white12))),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
          SizedBox(height: 30),
          Text("YENİ PARÇA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
          SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: () => pickImage(ImageSource.gallery),
              child: Container(
                decoration: BoxDecoration(color: Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: kIsWeb 
                             ? Image.network(_selectedImage!.path, fit: BoxFit.contain)
                             : Image.file(File(_selectedImage!.path), fit: BoxFit.contain),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.white24, size: 50), SizedBox(height: 10), Text("Fotoğraf Seç", style: TextStyle(color: Colors.grey))]),
              ),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isUploading ? null : uploadImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: isUploading 
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)), SizedBox(width: 10), Text("İŞLENİYOR...")])
                  : Text("ANALİZ ET & EKLE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          )
        ],
      ),
    );
  }
}