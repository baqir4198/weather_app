import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_service.dart';
import 'dart:async';
import 'package:adhan/adhan.dart';

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  String _cityName = "Fetching City...";
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;

  List<Map<String, dynamic>> _hourlyForecast = [];
  bool _showHourly = false;

  bool _isCelsius = true;
  String _greeting = "";
  bool _isDayTime = true;
  int _maghribHour = 18;
  int _maghribMinute = 0;
  Timer? _themeCheckTimer;

  double _userLatitude = 0.0;
  double _userLongitude = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _updateGreeting();
    _startThemeCheckTimer();
  }

  @override
  void dispose() {
    _themeCheckTimer?.cancel();
    super.dispose();
  }

  void _calculateMaghribTime(double latitude, double longitude) {
    try {
      final coordinates = Coordinates(latitude, longitude);
      final params = CalculationMethod.muslim_world_league.getParameters();
      final prayerTimes = PrayerTimes.today(coordinates, params);

      final maghribDateTime = prayerTimes.maghrib;

      _maghribHour = maghribDateTime.hour;
      _maghribMinute = maghribDateTime.minute;

      print("📍 Accurate Maghrib time for today: ${_maghribHour.toString().padLeft(2, '0')}:${_maghribMinute.toString().padLeft(2, '0')}");

      _checkDayNightBasedOnMaghrib();
    } catch (e) {
      print("Error calculating Maghrib time: $e");
      _fallbackMaghribTime();
    }
  }

  void _fallbackMaghribTime() {
    final now = DateTime.now();
    final month = now.month;

    if (month >= 4 && month <= 9) {
      _maghribHour = 19;
      _maghribMinute = 15;
    } else if (month >= 10 && month <= 11) {
      _maghribHour = 17;
      _maghribMinute = 45;
    } else if (month >= 12 && month <= 2) {
      _maghribHour = 17;
      _maghribMinute = 15;
    } else {
      _maghribHour = 18;
      _maghribMinute = 30;
    }

    print("📅 Using fallback Maghrib time: $_maghribHour:$_maghribMinute");
    _checkDayNightBasedOnMaghrib();
  }

  void _checkDayNightBasedOnMaghrib() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    final currentTotalMinutes = currentHour * 60 + currentMinute;
    final maghribTotalMinutes = _maghribHour * 60 + _maghribMinute;

    setState(() {
      _isDayTime = currentTotalMinutes < maghribTotalMinutes;
    });

    print("🌓 Theme: ${_isDayTime ? 'Day (Before Maghrib)' : 'Night (After Maghrib)'}");
    print("Current time: ${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}");
    print("Maghrib time: ${_maghribHour.toString().padLeft(2, '0')}:${_maghribMinute.toString().padLeft(2, '0')}");
  }

  void _startThemeCheckTimer() {
    _themeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDayNightBasedOnMaghrib();
      _updateGreeting();
    });
  }

  void _updateGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    final isAfterMaghrib = !_isDayTime;

    setState(() {
      if (!isAfterMaghrib) {
        if (hour < 12) {
          _greeting = "Good Morning ☀️";
        } else if (hour < 17) {
          _greeting = "Good Afternoon 🌤️";
        } else {
          _greeting = "Good Evening 🌅";
        }
      } else {
        if (hour < 21) {
          _greeting = "Good Evening 🌙";
        } else {
          _greeting = "Good Night 🌃";
        }
      }
    });
  }

  Color _getAppBarColor() {
    if (_isDayTime) {
      return const Color(0xFF87CEEB).withOpacity(0.9);
    } else {
      return const Color(0xFF0A0A2A).withOpacity(0.95);
    }
  }

  Color _getBackgroundColor(String condition) {
    if (_isDayTime) {
      switch(condition.toLowerCase()) {
        case 'clear sky':
          return const Color(0xFF87CEEB);
        case 'partly cloudy':
          return const Color(0xFFB0C4DE);
        case 'cloudy':
          return const Color(0xFF9CA3AF);
        case 'raining':
        case 'drizzling':
          return const Color(0xFF6B7280);
        default:
          return const Color(0xFF87CEEB);
      }
    } else {
      switch(condition.toLowerCase()) {
        case 'clear sky':
          return const Color(0xFF0A0A2A);
        case 'partly cloudy':
          return const Color(0xFF1A1A3A);
        case 'cloudy':
          return const Color(0xFF0F0F2A);
        case 'raining':
        case 'drizzling':
          return const Color(0xFF05051A);
        default:
          return const Color(0xFF0A0A2A);
      }
    }
  }

  Color _getTextColor() {
    return _isDayTime ? Colors.black87 : Colors.white;
  }

  Color _getSubtitleColor() {
    return _isDayTime ? Colors.black54 : Colors.white70;
  }

  Color _getCardColor() {
    if (_isDayTime) {
      return Colors.white.withOpacity(0.3);
    } else {
      return Colors.white.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    if (_isDayTime) {
      return Colors.white.withOpacity(0.5);
    } else {
      return Colors.white.withOpacity(0.2);
    }
  }

  List<Color> _getGradientColors(String condition) {
    if (_isDayTime) {
      switch(condition.toLowerCase()) {
        case 'clear sky':
          return [const Color(0xFF87CEEB), const Color(0xFFE0F6FF)];
        case 'partly cloudy':
          return [const Color(0xFFB0C4DE), const Color(0xFFD4E6F1)];
        case 'cloudy':
          return [const Color(0xFF9CA3AF), const Color(0xFFD1D5DB)];
        case 'raining':
        case 'drizzling':
          return [const Color(0xFF6B7280), const Color(0xFF9CA3AF)];
        default:
          return [const Color(0xFF87CEEB), const Color(0xFFE0F6FF)];
      }
    } else {
      switch(condition.toLowerCase()) {
        case 'clear sky':
          return [const Color(0xFF0A0A2A), const Color(0xFF1A1A4A)];
        case 'partly cloudy':
          return [const Color(0xFF1A1A3A), const Color(0xFF2A2A5A)];
        case 'cloudy':
          return [const Color(0xFF0F0F2A), const Color(0xFF1F1F4A)];
        case 'raining':
        case 'drizzling':
          return [const Color(0xFF05051A), const Color(0xFF0F0F2A)];
        default:
          return [const Color(0xFF0A0A2A), const Color(0xFF1A1A4A)];
      }
    }
  }

  String _getWeatherAdvice(String condition, int temp) {
    if (condition.contains("Rain") || condition.contains("Drizzle")) {
      return _isDayTime ? "Don't forget your umbrella! ☔" : "Rainy evening! Stay cozy inside 🌙☔";
    } else if (condition.contains("Snow")) {
      return "Wear warm clothes! ❄️";
    } else if (temp > 30) {
      return _isDayTime ? "It's hot! Stay hydrated 💧" : "Warm night! Keep cool 😎🌙";
    } else if (temp < 10) {
      return _isDayTime ? "It's cold! Wear a jacket 🧥" : "Cold evening! Bundle up 🧥🌙";
    } else if (condition.contains("Clear") || condition.contains("Sun")) {
      return _isDayTime ? "Perfect day to go outside! 🌞" : "Clear night! Perfect for stargazing ✨🌙";
    } else if (condition.contains("Cloud")) {
      return _isDayTime ? "Nice weather for a walk 🚶" : "Cloudy evening! Cozy weather ☁️🌙";
    } else {
      return _isDayTime ? "Have a great day! ✨" : "Have a peaceful evening! 🌙✨";
    }
  }

  String _getTemperature(int tempCelsius) {
    if (_isCelsius) {
      return "$tempCelsius°C";
    } else {
      int tempF = (tempCelsius * 9 / 5 + 32).round();
      return "$tempF°F";
    }
  }

  String _getWeatherEmoji(String condition) {
    switch(condition.toLowerCase()) {
      case 'clear sky':
        return _isDayTime ? '☀️' : '🌙';
      case 'partly cloudy':
        return _isDayTime ? '⛅' : '☁️🌙';
      case 'cloudy':
        return '☁️';
      case 'drizzling':
        return '🌦️';
      case 'raining':
        return '🌧️';
      case 'snowing':
        return '❄️';
      default:
        return _isDayTime ? '🌡️' : '🌙';
    }
  }

  String _getHourlyWeatherIcon(int weatherCode) {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode >= 51 && weatherCode <= 57) return '🌦️';
    if (weatherCode >= 61 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 77) return '❄️';
    if (weatherCode >= 95 && weatherCode <= 99) return '⛈️';
    return '☁️';
  }

  Future<void> _refreshWeather() async {
    setState(() {
      _isLoading = true;
      _showHourly = false;
    });
    await _loadWeather();
  }

  void _toggleTemperatureUnit() {
    setState(() {
      _isCelsius = !_isCelsius;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCelsius ? "Showing Celsius °C" : "Showing Fahrenheit °F"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleHourlyView() {
    setState(() {
      _showHourly = !_showHourly;
    });
  }

  String _getDetailedInfo() {
    if (_weatherData == null) return "";
    final current = _weatherData!['current'];
    final temp = current['temperature_2m'].round();
    final condition = _weatherService.interpretCode(current['weather_code']);
    final humidity = current['relative_humidity_2m'];
    final wind = current['wind_speed_10m'];

    return "Temperature: ${_getTemperature(temp)}\n"
        "Condition: $condition\n"
        "Humidity: $humidity%\n"
        "Wind Speed: $wind km/h\n"
        "Maghrib: ${_maghribHour.toString().padLeft(2, '0')}:${_maghribMinute.toString().padLeft(2, '0')}\n"
        "Time: ${_isDayTime ? 'Day (Before Maghrib)' : 'Night (After Maghrib)'} 🕌";
  }

  void _showWeatherDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(_getWeatherEmoji(_weatherService.interpretCode(_weatherData!['current']['weather_code']))),
            const SizedBox(width: 10),
            Text(_cityName),
          ],
        ),
        content: Text(_getDetailedInfo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _parseHourlyForecast(Map<String, dynamic> data) {
    if (data.containsKey('hourly')) {
      final hourly = data['hourly'];

      if (hourly.containsKey('time') &&
          hourly.containsKey('temperature_2m') &&
          hourly.containsKey('weather_code')) {

        final List<dynamic> times = hourly['time'];
        final List<dynamic> temperatures = hourly['temperature_2m'];
        final List<dynamic> weatherCodes = hourly['weather_code'];

        _hourlyForecast.clear();

        DateTime now = DateTime.now();
        int currentHour = now.hour;

        int startIndex = 0;
        for (int i = 0; i < times.length; i++) {
          DateTime time = DateTime.parse(times[i]);
          if (time.hour >= currentHour) {
            startIndex = i;
            break;
          }
        }

        int itemsAdded = 0;
        for (int i = startIndex; i < times.length && itemsAdded < 24; i++) {
          DateTime time = DateTime.parse(times[i]);
          String hour = "${time.hour.toString().padLeft(2, '0')}:00";

          int temp = temperatures[i] is int
              ? temperatures[i]
              : (temperatures[i] as double).round();

          int code = weatherCodes[i] is int
              ? weatherCodes[i]
              : (weatherCodes[i] as double).round();

          _hourlyForecast.add({
            'time': hour,
            'temp': temp,
            'code': code,
            'icon': _getHourlyWeatherIcon(code),
          });

          itemsAdded++;
        }

        if (_hourlyForecast.isEmpty) {
          _addMockHourlyData();
        }
      } else {
        _addMockHourlyData();
      }
    } else {
      _addMockHourlyData();
    }
  }

  void _addMockHourlyData() {
    _hourlyForecast.clear();
    DateTime now = DateTime.now();

    for (int i = 0; i < 24; i++) {
      DateTime futureTime = now.add(Duration(hours: i));
      String hour = "${futureTime.hour.toString().padLeft(2, '0')}:00";

      int mockTemp = 18 + (i % 12);
      if (mockTemp > 30) mockTemp = 30;
      if (mockTemp < 10) mockTemp = 10;

      int mockCode = i % 6 == 0 ? 0 : (i % 6 == 1 ? 2 : (i % 6 == 2 ? 3 : (i % 6 == 3 ? 61 : (i % 6 == 4 ? 51 : 0))));

      _hourlyForecast.add({
        'time': hour,
        'temp': mockTemp,
        'code': mockCode,
        'icon': _getHourlyWeatherIcon(mockCode),
      });
    }
  }

  _loadWeather() async {
    try {
      final data = await _weatherService.fetchLocalWeather();
      double lat = data['latitude'];
      double lon = data['longitude'];
      String city = await _weatherService.getCityName(lat, lon);

      _userLatitude = lat;
      _userLongitude = lon;

      _calculateMaghribTime(lat, lon);

      _parseHourlyForecast(data);

      setState(() {
        _weatherData = data;
        _cityName = city;
        _isLoading = false;
      });

      _updateGreeting();

    } catch (e) {
      print("ERROR: $e");
      setState(() { _isLoading = false; });
    }
  }

  String getWeatherAnimation(String? condition){
    if(condition == null) return 'assets/sun.json';
    switch(condition.toLowerCase()){
      case 'clear sky':
        return _isDayTime ? 'assets/sun.json' : 'assets/moon.json';
      case 'partly cloudy':
        return 'assets/partly_cloudy.json';
      case 'cloudy':
        return 'assets/cloudy.json';
      case 'drizzling':
        return 'assets/drizzling.json';
      case 'raining':
        return 'assets/rainy.json';
      default:
        return 'assets/sun.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_isLoading){
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_weatherData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Couldn't get weather data."),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadWeather,
                child: const Text("Try Again"),
              ),
            ],
          ),
        ),
      );
    }

    final current = _weatherData!['current'];
    final temp = current['temperature_2m'].round();
    final condition = _weatherService.interpretCode(current['weather_code']);
    final humidity = current['relative_humidity_2m'];
    final wind = current['wind_speed_10m'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _greeting,
          style: TextStyle(
            color: _getTextColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: _getAppBarColor(),
        shadowColor: _isDayTime ? Colors.black26 : Colors.black54,
        actions: [
          IconButton(
            icon: Icon(_showHourly ? Icons.today : Icons.schedule,
                color: _getTextColor()),
            onPressed: _toggleHourlyView,
            tooltip: _showHourly ? "Show Current" : "Show Hourly",
          ),
          IconButton(
            icon: Text(_isCelsius ? "°C" : "°F",
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor())),
            onPressed: _toggleTemperatureUnit,
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: _getTextColor()),
            onPressed: _showWeatherDetails,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeather,
        color: _isDayTime ? Colors.blue : Colors.white,
        backgroundColor: _isDayTime ? Colors.white : const Color(0xFF0A0A2A),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getGradientColors(condition),
            ),
          ),
          child: _showHourly ? _buildHourlyForecast() : _buildCurrentWeather(),
        ),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final current = _weatherData!['current'];
    final temp = current['temperature_2m'].round();
    final condition = _weatherService.interpretCode(current['weather_code']);
    final humidity = current['relative_humidity_2m'];
    final wind = current['wind_speed_10m'];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: _getCardColor(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getBorderColor()),
            ),
            child: Text(
              _getWeatherAdvice(condition, temp),
              style: TextStyle(fontSize: 14, color: _getTextColor()),
            ),
          ),

          Text(
            _cityName,
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w500, color: _getTextColor()),
          ),

          Center(
            child: Lottie.asset(
              getWeatherAnimation(condition),
              width: 220,
              height: 220,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: _getCardColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isDayTime ? Icons.wb_sunny : Icons.nightlight_round,
                    size: 80,
                    color: _getTextColor(),
                  ),
                );
              },
            ),
          ),

          GestureDetector(
            onTap: _toggleTemperatureUnit,
            child: Text(
              _getTemperature(temp),
              style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: _getTextColor()),
            ),
          ),

          const SizedBox(height: 10),
          Text(condition, style: TextStyle(color: _getSubtitleColor(), fontSize: 18)),

          Text(
            _getWeatherEmoji(condition),
            style: const TextStyle(fontSize: 30),
          ),

          const SizedBox(height: 40),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getCardColor(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getBorderColor()),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _weatherDetail("Humidity", "$humidity%"),
                  _weatherDetail("Wind", "$wind km/h"),
                  _weatherDetail("Feels Like", _getTemperature(_weatherData!['current']['apparent_temperature'].round())),
                ]
            ),
          ),

          const SizedBox(height: 20),

          TextButton.icon(
            onPressed: _refreshWeather,
            icon: Icon(Icons.refresh, color: _getTextColor()),
            label: Text("Refresh Weather", style: TextStyle(color: _getTextColor())),
            style: TextButton.styleFrom(
              foregroundColor: _getTextColor(),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    if (_hourlyForecast.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No hourly data available", style: TextStyle(color: _getTextColor())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showHourly = false;
                });
                _refreshWeather();
              },
              child: const Text("Back to Current Weather"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Text(
                "24-Hour Forecast",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getTextColor()),
              ),
              const SizedBox(height: 5),
              Text(
                "Next ${_hourlyForecast.length} hours",
                style: TextStyle(fontSize: 12, color: _getSubtitleColor()),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: ListView.builder(
            itemCount: _hourlyForecast.length,
            itemBuilder: (context, index) {
              final hour = _hourlyForecast[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: _getCardColor(),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: _getSubtitleColor()),
                        const SizedBox(width: 8),
                        Text(
                          hour['time'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      hour['icon'],
                      style: const TextStyle(fontSize: 28),
                    ),
                    Text(
                      _getTemperature(hour['temp']),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: _toggleHourlyView,
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back to Current Weather"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getCardColor(),
            foregroundColor: _getTextColor(),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _weatherDetail(String label, String value){
    return Column(
      children: [
        Text(label, style: TextStyle(color: _getSubtitleColor(), fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _getTextColor())),
      ],
    );
  }
}