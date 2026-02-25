import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Widget utama ChatScreen
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

// State untuk ChatScreen
class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _showWelcomeAnimation = true;
  late AnimationController _welcomeAnimationController;

  // Definisi warna tema aplikasi
  final Color primaryColor = Color(0xFF8A56AC);
  final Color secondaryColor = Color(0xFF72B8E4);
  final Color bgGradientStart = Color(0xFF5D4A9C);
  final Color bgGradientEnd = Color(0xFF8A7BC8);

  @override
  void initState() {
    super.initState();
    _weatherService.loadWeatherData();
    initializeDateFormatting('id_ID', null);

    // Setup animasi welcome
    _welcomeAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 8))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() => _showWelcomeAnimation = false);
              _showInstructionDialog();
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _welcomeAnimationController.dispose();
    super.dispose();
  }

  // Menampilkan dialog instruksi penggunaan
  void _showInstructionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        title: Row(
          children: [
            Icon(Icons.cloud, color: primaryColor),
            SizedBox(width: 10),
            Text(
              'Selamat Datang!',
              style:
                  TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Terima kasih telah menggunakan aplikasi cuaca ini!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Aplikasi ini masih dalam tahap pengembangan.'),
              SizedBox(height: 10),
              Text('Berikut adalah instruksi penggunaan:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  '- Bot hanya akan menjawab berdasarkan input "nama tempat" setelah kata "cuaca".'),
              Text(
                  '  Contoh: "cuaca Salatiga", "bagaimana ya cuaca Pasar Baru", dll.'),
              SizedBox(height: 5),
              Text(
                  '- Bot akan gagal menjawab jika ada kata tambahan di awal atau akhir "nama tempat".'),
              Text(
                  '- Data wilayah diambil dari BMKG dengan kode wilayah tingkat IV.'),
              Text(
                  '- Perlu diketahui waktu yang ditampilkan adalah waktu dari update prakiraan terakhir response API BMKG.'),
              SizedBox(height: 10),
              Text(
                  '- aplikasi masih dalam tahap pengembangan,mungkin beberapa nama tempat belum tersedia'),
              SizedBox(height: 10),
              Text('Selamat mencoba!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // BAGIAN PROSES PENGIRIMAN PESAN (LINE 154-233)
  // Menangani pengiriman pesan dari pengguna dan memproses responnya
  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    setState(() => _messages.insert(
        0,
        ChatMessage(
          text: text,
          isUser: true,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        )));

    final lowerCaseText = text.toLowerCase().trim();

    // Cek apakah pesan berisi kata 'cuaca'
    if (lowerCaseText.contains('cuaca')) {
      final parts = lowerCaseText.split('cuaca');
      if (parts.length > 1) {
        final regionName = parts[1].trim();
        final regionCode = _weatherService.getRegionCode(regionName);

        // PERUBAHAN: Menghilangkan pesan loading
        // Langsung proses data cuaca

        if (regionCode != null) {
          WeatherData? weatherData =
              await _weatherService.fetchWeatherData(regionCode);

          if (weatherData != null) {
            _addBotMessage(weatherData);
          } else {
            _addBotMessage(_createErrorWeatherData(
                'Terjadi kesalahan yang tidak terduga.',
                area: regionName));
          }
        } else {
          _addBotMessage(_createErrorWeatherData(
            'Lokasi tidak ditemukan, mohon tidak memberi kalimat tambahan setelah nama tempat.',
            area: regionName,
          ));
        }
      } else {
        _addBotMessage(_createErrorWeatherData(
          'Sebutkan nama tempat setelah kata "cuaca" (contoh: cuaca Salatiga).',
        ));
      }
    } else {
      _addBotMessage(_createErrorWeatherData(
        'Maaf, saya hanya menjawab pertanyaan terkait cuaca. Coba tanya tentang "cuaca [nama tempat]".',
      ));
    }
  }

  // Membuat objek WeatherData dengan pesan error
  WeatherData _createErrorWeatherData(String message, {String area = ''}) {
    return WeatherData(
        area: area,
        temperature: '',
        weatherCondition: message,
        humidity: '',
        localDateTime: null);
  }

  // BAGIAN PEMBUATAN PESAN BOT (LINE 234-273)
  // Menambahkan pesan dari bot ke dalam daftar pesan
  void _addBotMessage(WeatherData weatherData) {
    String formattedDateTime = '';
    if (weatherData.localDateTime != null) {
      try {
        formattedDateTime = DateFormat('EEEE, d MMMM HH:mm WIB', 'id_ID')
            .format(weatherData.localDateTime!);
      } catch (e) {
        print('Error memformat tanggal: $e');
      }
    }

    final messageText = weatherData.area.isNotEmpty &&
            weatherData.temperature.isNotEmpty
        ? 'Prakiraan cuaca di ${weatherData.area}${formattedDateTime.isNotEmpty ? ' pada $formattedDateTime' : ''}:\n'
            'Suhu: ${weatherData.temperature}\n'
            'Kondisi: ${weatherData.weatherCondition}\n'
            'Kelembaban: ${weatherData.humidity}.'
        : weatherData.weatherCondition;

    setState(() => _messages.insert(
        0,
        ChatMessage(
          text: messageText,
          isUser: false,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          weatherData:
              weatherData.area.isNotEmpty && weatherData.temperature.isNotEmpty
                  ? weatherData
                  : null,
          formattedDateTime: formattedDateTime,
        )));
  }

  // BAGIAN UI KOMPONEN INPUT (LINE 274-307)
  // Membangun komponen input teks dengan desain yang menarik
  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16.0),
          Icon(Icons.cloud_queue, color: primaryColor),
          SizedBox(width: 8.0),
          Flexible(
            child: TextField(
              controller: _messageController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Tanyakan tentang cuaca...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(30.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30.0),
              onTap: () => _handleSubmitted(_messageController.text),
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: Icon(Icons.send, color: Colors.white, size: 22.0),
              ),
            ),
          ),
          SizedBox(width: 4.0),
        ],
      ),
    );
  }

  // BAGIAN UI UTAMA (LINE 308-428)
  // Membangun UI utama aplikasi
  @override
  Widget build(BuildContext context) {
    return _showWelcomeAnimation
        ? Scaffold(
            body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgGradientStart, bgGradientEnd],
              ),
            ),
            child: Center(
              child: Lottie.asset('assets/animations/welcome.json',
                  controller: _welcomeAnimationController, fit: BoxFit.contain),
            ),
          ))
        : Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor.withOpacity(0.8)],
                  ),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'CUACAIN AJAH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.help_outline, color: Colors.white),
                  onPressed: _showInstructionDialog,
                )
              ],
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgGradientStart.withOpacity(0.6),
                    bgGradientEnd.withOpacity(0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.6,
                      child: Lottie.asset(
                        'assets/animations/animasibg.json',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Tanyakan tentang cuaca di lokasi manapun di Indonesia',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3.0,
                                    color: Colors.black26),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _messages.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(
                                        'assets/animations/bot_avatar.json',
                                        width: 120,
                                        height: 120,
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Coba tanya "cuaca Salatiga" atau "cuaca Blotongan"',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.all(12.0),
                                  reverse: true,
                                  itemBuilder: (_, int index) =>
                                      _messages[index],
                                  itemCount: _messages.length,
                                ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'by: EL orangkeren',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontStyle: FontStyle.italic,
                              shadows: [
                                Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3.0,
                                    color: Colors.black26),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _buildTextComposer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

// BAGIAN WIDGET PESAN CHAT (LINE 429-589)
// Widget untuk menampilkan pesan dalam format bubble chat
class ChatMessage extends StatelessWidget {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading =
        false, // Parameter ini masih dipertahankan untuk kompatibilitas
    this.weatherData,
    this.formattedDateTime = '',
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String text;
  final bool isUser;
  final bool isLoading;
  final WeatherData? weatherData;
  final String formattedDateTime;
  final Color primaryColor;
  final Color secondaryColor;

  // Mendapatkan ikon berdasarkan kondisi cuaca
  String _getWeatherIcon() {
    if (weatherData == null) return '';

    final condition = weatherData!.weatherCondition.toLowerCase();

    if (condition.contains('hujan') || condition.contains('petir')) {
      return '🌧️';
    } else if (condition.contains('berawan')) {
      return '☁️';
    } else if (condition.contains('cerah berawan')) {
      return '🌤️';
    } else if (condition.contains('cerah')) {
      return '☀️';
    } else if (condition.contains('kabut')) {
      return '🌫️';
    } else {
      return '🌦️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.8),
                radius: 20,
                child: Lottie.asset(
                  'assets/animations/bot_avatar.json',
                  width: 36.0,
                  height: 36.0,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isUser ? 'Me' : 'Kak Cuaca',
                  style: TextStyle(
                    color: isUser ? secondaryColor : primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUser
                        ? secondaryColor.withOpacity(0.2)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (weatherData != null && weatherData!.area.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withOpacity(0.8),
                                secondaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getWeatherIcon()} ${weatherData!.area}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (formattedDateTime.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    formattedDateTime,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              Divider(color: Colors.white.withOpacity(0.5)),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Suhu: ${weatherData!.temperature}',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Kelembaban: ${weatherData!.humidity}',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    weatherData!.weatherCondition,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          text,
                          style: TextStyle(color: Colors.black87),
                          textAlign: isUser ? TextAlign.right : TextAlign.left,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 12.0),
              child: CircleAvatar(
                backgroundColor: secondaryColor,
                radius: 20,
                backgroundImage: AssetImage('assets/images/user_avatar.png'),
              ),
            ),
        ],
      ),
    );
  }
}
