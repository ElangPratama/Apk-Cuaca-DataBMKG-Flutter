class WeatherData {
  final String area;
  final String temperature;
  final String weatherCondition;
  final String humidity;
  final DateTime? localDateTime; // Tambahkan ini

  WeatherData({
    required this.area,
    required this.temperature,
    required this.weatherCondition,
    required this.humidity,
    this.localDateTime, // Tambahkan ini
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      area: json['area'] ?? 'Tidak Diketahui',
      temperature: json['tempC']?.toString() ?? 'Tidak Diketahui',
      weatherCondition: json['weather'] ?? 'Tidak Diketahui',
      humidity: json['humidity'] ?? 'Tidak Diketahui',
      localDateTime: json['local_datetime'] != null
          ? DateTime.parse(json['local_datetime'])
          : null, // Parse local_datetime jika ada
    );
  }
}
