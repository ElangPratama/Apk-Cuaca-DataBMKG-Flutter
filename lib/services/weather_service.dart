import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import 'package:flutter/services.dart';

class WeatherService {
  Map<String, String> _regionCodeMap = {};

  Future<void> loadWeatherData() async {
    print('Memulai memuat data cuaca (rootBundle)...');
    try {
      final String data =
          await rootBundle.loadString('assets/weather_data.csv');
      final lines = data.split('\n');
      for (final line in lines) {
        final parts = line.split(',');
        if (parts.length >= 2) {
          final code = parts[0].trim();
          final name = parts
              .sublist(1)
              .join(',')
              .trim()
              .toLowerCase(); // Normalisasi nama saat dimuat
          _regionCodeMap[name] = code;
        } else {
          print('Baris tidak valid (kurang dari 2 kolom): $line');
        }
      }
      print(
          'Data cuaca (rootBundle) berhasil dimuat. Jumlah daerah: ${_regionCodeMap.length}');
    } catch (e) {
      print('Gagal memuat data cuaca (rootBundle): $e');
    }
    print('Selesai memuat data cuaca (rootBundle).');
  }

  String? getRegionCode(String regionName) {
    final normalizedRegionName = regionName.toLowerCase().trim();
    print('Mencari kode wilayah untuk: $normalizedRegionName');
    return _regionCodeMap[normalizedRegionName];
  }

  Future<WeatherData?> fetchWeatherData(String regionCode) async {
    final apiUrl =
        'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=$regionCode';
    print('Memanggil API: $apiUrl');
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        print("--- Seluruh Respons JSON dari API ---");
        print(response.body);
        print("--- Akhir Respons JSON ---");

        final decodedData = jsonDecode(response.body);
        if (decodedData != null) {
          print('Data berhasil di-decode: $decodedData'); // Tambahkan ini

          try {
            // Mulai blok try
            final lokasi = decodedData['lokasi'];
            final dataPrakiraan = decodedData['data'];

            if (lokasi != null &&
                dataPrakiraan != null &&
                dataPrakiraan is List &&
                dataPrakiraan.isNotEmpty) {
              final prakiraanHarian =
                  dataPrakiraan[0]['cuaca']; // Ini adalah List<List<Object>>

              if (prakiraanHarian != null &&
                  prakiraanHarian is List &&
                  prakiraanHarian.isNotEmpty) {
                final prakiraanSaatIni = prakiraanHarian[0]
                    [0]; // Ambil prakiraan pertama dalam list pertama

                if (prakiraanSaatIni != null) {
                  final areaName = lokasi['desa'] ?? 'Tidak Diketahui';
                  final temperature =
                      prakiraanSaatIni['t']?.toString() ?? 'Tidak Diketahui';
                  final weatherCondition =
                      prakiraanSaatIni['weather_desc'] ?? 'Tidak Diketahui';
                  final humidity =
                      prakiraanSaatIni['hu']?.toString() ?? 'Tidak Diketahui';
                  // Ambil local_datetime dari elemen yang sama (prakiraanSaatIni)
                  final localDateTimeString =
                      prakiraanSaatIni['local_datetime'] as String?;
                  final localDateTime = localDateTimeString != null
                      ? DateTime.parse(localDateTimeString)
                      : null;

                  return WeatherData(
                    area: areaName,
                    temperature: '$temperature°C',
                    weatherCondition: weatherCondition,
                    humidity: '$humidity%',
                    localDateTime: localDateTime,
                  );
                }
              }
            }
            print('Struktur respons API tidak sesuai dengan yang diharapkan.');
            return null;
          } catch (e) {
            // Tangkap error yang terjadi saat pemrosesan data
            print('Error saat memproses decodedData: $e');
            return null; // Mengembalikan null menandakan kegagalan
          }
        } else {
          print('Respons API kosong atau null.');
          return null;
        }
      } else {
        print(
            'Gagal memuat data cuaca dari API. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error saat memanggil API: $e');
      return null;
    }
  }
}
