import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_service.dart';

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

  // NEW: Add these variables
  bool _isCelsius = true;
  String _greeting = "";

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _updateGreeting();
  }

  // NEW FUNCTION 1: Update greeting based on time of day
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = "Good Morning ☀️";
      } else if (hour < 17) {
        _greeting = "Good Afternoon 🌤️";
      } else if (hour < 21) {
        _greeting = "Good Evening 🌙";
      } else {
        _greeting = "Good Night 🌃";
      }
    });
  }

  // NEW FUNCTION 2: Convert temperature between Celsius and Fahrenheit
  String _getTemperature(int tempCelsius) {
    if (_isCelsius) {
      return "$tempCelsius°C";
    } else {
      int tempF = (tempCelsius * 9 / 5 + 32).round();
      return "$tempF°F";
    }
  }

  // NEW FUNCTION 3: Get weather advice based on conditions
  String _getWeatherAdvice(String condition, int temp) {
    if (condition.contains("Rain") || condition.contains("Drizzle")) {
      return "Don't forget your umbrella! ☔";
    } else if (condition.contains("Snow")) {
      return "Wear warm clothes! ❄️";
    } else if (temp > 30) {
      return "It's hot! Stay hydrated 💧";
    } else if (temp < 10) {
      return "It's cold! Wear a jacket 🧥";
    } else if (condition.contains("Clear") || condition.contains("Sun")) {
      return "Perfect day to go outside! 🌞";
    } else if (condition.contains("Cloud")) {
      return "Nice weather for a walk 🚶";
    } else {
      return "Have a great day! ✨";
    }
  }

  // NEW FUNCTION 4: Get weather icon emoji
  String _getWeatherEmoji(String condition) {
    switch(condition.toLowerCase()) {
      case 'clear sky':
        return '☀️';
      case 'partly cloudy':
        return '⛅';
      case 'cloudy':
        return '☁️';
      case 'drizzling':
        return '🌦️';
      case 'raining':
        return '🌧️';
      case 'snowing':
        return '❄️';
      default:
        return '🌡️';
    }
  }

  // NEW FUNCTION 5: Refresh weather data
  Future<void> _refreshWeather() async {
    setState(() {
      _isLoading = true;
    });
    await _loadWeather();
  }

  // NEW FUNCTION 6: Toggle temperature unit
  void _toggleTemperatureUnit() {
    setState(() {
      _isCelsius = !_isCelsius;
    });
    // Show snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCelsius ? "Showing Celsius °C" : "Showing Fahrenheit °F"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // NEW FUNCTION 7: Share weather info (simulated)
  void _shareWeather() {
    final current = _weatherData!['current'];
    final temp = current['temperature_2m'].round();
    final condition = _weatherService.interpretCode(current['weather_code']);

    // In a real app, you would use the share package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("📱 Weather in $_cityName: ${_getTemperature(temp)}, $condition"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // NEW FUNCTION 8: Get detailed weather info
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
        "Wind Speed: $wind km/h";
  }

  // NEW FUNCTION 9: Show weather details dialog
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

  // NEW FUNCTION 10: Get background color based on weather
  Color _getBackgroundColor(String condition) {
    switch(condition.toLowerCase()) {
      case 'clear sky':
        return const Color(0xFF2E335A);
      case 'partly cloudy':
        return const Color(0xFF3A3F6E);
      case 'cloudy':
        return const Color(0xFF2A2F55);
      case 'raining':
      case 'drizzling':
        return const Color(0xFF1A1F45);
      default:
        return const Color(0xFF2E335A);
    }
  }

  _loadWeather() async {
    try {
      final data = await _weatherService.fetchLocalWeather();
      double lat = data['latitude'];
      double lon = data['longitude'];
      String city = await _weatherService.getCityName(lat, lon);

      setState(() {
        _weatherData = data;
        _cityName = city;
        _isLoading = false;
      });

      // Update greeting after weather loads
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
        return 'assets/sun.json';
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
        title: Text(_greeting),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Temperature unit toggle button
          IconButton(
            icon: Text(_isCelsius ? "°C" : "°F", style: const TextStyle(fontSize: 18)),
            onPressed: _toggleTemperatureUnit,
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareWeather,
          ),
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showWeatherDetails,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeather,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getBackgroundColor(condition),
                    const Color(0xFF1C1B33)
                  ]
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Weather advice chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getWeatherAdvice(condition, temp),
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              Text(_cityName, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w500)),

              // Weather animation
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
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud,
                        size: 80,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    );
                  },
                ),
              ),

              // Temperature with toggle
              GestureDetector(
                onTap: _toggleTemperatureUnit,
                child: Text(
                  _getTemperature(temp),
                  style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),
              Text(condition, style: const TextStyle(color: Colors.grey, fontSize: 18)),

              // Weather emoji
              Text(
                _getWeatherEmoji(condition),
                style: const TextStyle(fontSize: 30),
              ),

              const SizedBox(height: 40),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
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

              // Refresh button
              TextButton.icon(
                onPressed: _refreshWeather,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Weather"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherDetail(String label, String value){
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}