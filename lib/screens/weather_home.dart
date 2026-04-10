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

  // Hourly forecast data
  List<Map<String, dynamic>> _hourlyForecast = [];
  bool _showHourly = false;

  // Add these variables
  bool _isCelsius = true;
  String _greeting = "";

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _updateGreeting();
  }

  // FUNCTION 1: Update greeting based on time of day
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

  // FUNCTION 2: Convert temperature between Celsius and Fahrenheit
  String _getTemperature(int tempCelsius) {
    if (_isCelsius) {
      return "$tempCelsius°C";
    } else {
      int tempF = (tempCelsius * 9 / 5 + 32).round();
      return "$tempF°F";
    }
  }

  // FUNCTION 3: Get weather advice based on conditions
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

  // FUNCTION 4: Get weather icon emoji
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

  // FUNCTION 5: Get weather icon for hourly forecast
  String _getHourlyWeatherIcon(int weatherCode) {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode >= 51 && weatherCode <= 57) return '🌦️';
    if (weatherCode >= 61 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 77) return '❄️';
    if (weatherCode >= 95 && weatherCode <= 99) return '⛈️';
    return '☁️';
  }

  // FUNCTION 6: Refresh weather data
  Future<void> _refreshWeather() async {
    setState(() {
      _isLoading = true;
      _showHourly = false;
    });
    await _loadWeather();
  }

  // FUNCTION 7: Toggle temperature unit
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

  // FUNCTION 8: Toggle hourly forecast view
  void _toggleHourlyView() {
    setState(() {
      _showHourly = !_showHourly;
    });
  }

  // FUNCTION 9: Get detailed weather info
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

  // FUNCTION 10: Show weather details dialog
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

  // FUNCTION 11: Get background color based on weather
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

  // FIXED FUNCTION 12: Parse hourly forecast from weather data
  void _parseHourlyForecast(Map<String, dynamic> data) {
    print("=== Parsing Hourly Forecast ===");

    if (data.containsKey('hourly')) {
      final hourly = data['hourly'];
      print("Hourly data keys: ${hourly.keys}");

      if (hourly.containsKey('time') &&
          hourly.containsKey('temperature_2m') &&
          hourly.containsKey('weather_code')) {

        final List<dynamic> times = hourly['time'];
        final List<dynamic> temperatures = hourly['temperature_2m'];
        final List<dynamic> weatherCodes = hourly['weather_code'];

        print("Times length: ${times.length}");
        print("Temperatures length: ${temperatures.length}");

        _hourlyForecast.clear();

        // Get current time to show from now onwards
        DateTime now = DateTime.now();
        int currentHour = now.hour;

        // Find starting index (current hour or next available)
        int startIndex = 0;
        for (int i = 0; i < times.length; i++) {
          DateTime time = DateTime.parse(times[i]);
          if (time.hour >= currentHour) {
            startIndex = i;
            break;
          }
        }

        // Get next 24 hours from current time
        int itemsAdded = 0;
        for (int i = startIndex; i < times.length && itemsAdded < 24; i++) {
          DateTime time = DateTime.parse(times[i]);
          String hour = "${time.hour.toString().padLeft(2, '0')}:00";

          // Safely get temperature
          int temp = 0;
          if (temperatures[i] is int) {
            temp = temperatures[i];
          } else if (temperatures[i] is double) {
            temp = (temperatures[i] as double).round();
          } else if (temperatures[i] is num) {
            temp = (temperatures[i] as num).toInt();
          }

          // Safely get weather code
          int code = 0;
          if (weatherCodes[i] is int) {
            code = weatherCodes[i];
          } else if (weatherCodes[i] is double) {
            code = (weatherCodes[i] as double).round();
          } else if (weatherCodes[i] is num) {
            code = (weatherCodes[i] as num).toInt();
          }

          _hourlyForecast.add({
            'time': hour,
            'temp': temp,
            'code': code,
            'icon': _getHourlyWeatherIcon(code),
          });

          itemsAdded++;
        }

        print("✅ Parsed ${_hourlyForecast.length} hours of forecast");

        // If no data found, add mock data for testing
        if (_hourlyForecast.isEmpty) {
          _addMockHourlyData();
        }
      } else {
        print("❌ Missing required hourly fields");
        _addMockHourlyData();
      }
    } else {
      print("❌ No hourly data in response");
      _addMockHourlyData();
    }
  }

  // Add mock data for testing if API doesn't return hourly data
  void _addMockHourlyData() {
    print("📊 Adding mock hourly data for testing");
    _hourlyForecast.clear();
    DateTime now = DateTime.now();

    for (int i = 0; i < 24; i++) {
      DateTime futureTime = now.add(Duration(hours: i));
      String hour = "${futureTime.hour.toString().padLeft(2, '0')}:00";

      // Mock temperatures (vary throughout the day)
      int mockTemp = 18 + (i % 12);
      if (mockTemp > 30) mockTemp = 30;
      if (mockTemp < 10) mockTemp = 10;

      // Mock weather codes (cycle through different weather types)
      int mockCode = 0;
      if (i % 6 == 0) mockCode = 0;      // Clear
      else if (i % 6 == 1) mockCode = 2;  // Partly cloudy
      else if (i % 6 == 2) mockCode = 3;  // Cloudy
      else if (i % 6 == 3) mockCode = 61; // Rain
      else if (i % 6 == 4) mockCode = 51; // Drizzle
      else mockCode = 0;                  // Clear

      _hourlyForecast.add({
        'time': hour,
        'temp': mockTemp,
        'code': mockCode,
        'icon': _getHourlyWeatherIcon(mockCode),
      });
    }

    print("✅ Added ${_hourlyForecast.length} hours of mock data");
  }

  _loadWeather() async {
    try {
      final data = await _weatherService.fetchLocalWeather();
      print("Weather data received: ${data.keys}");
      print("Has hourly? ${data.containsKey('hourly')}");

      double lat = data['latitude'];
      double lon = data['longitude'];
      String city = await _weatherService.getCityName(lat, lon);

      // Parse hourly forecast
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
          // Hourly forecast toggle button
          IconButton(
            icon: Icon(_showHourly ? Icons.today : Icons.schedule),
            onPressed: _toggleHourlyView,
            tooltip: _showHourly ? "Show Current" : "Show Hourly",
          ),
          // Temperature unit toggle button
          IconButton(
            icon: Text(_isCelsius ? "°C" : "°F", style: const TextStyle(fontSize: 18)),
            onPressed: _toggleTemperatureUnit,
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
          child: _showHourly ? _buildHourlyForecast() : _buildCurrentWeather(),
        ),
      ),
    );
  }

  // Build current weather view
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

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Build hourly forecast view
  Widget _buildHourlyForecast() {
    if (_hourlyForecast.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No hourly data available"),
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

        // Header with info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const Text(
                "24-Hour Forecast",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "Next ${_hourlyForecast.length} hours",
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Hourly forecast list
        Expanded(
          child: ListView.builder(
            itemCount: _hourlyForecast.length,
            itemBuilder: (context, index) {
              final hour = _hourlyForecast[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          hour['time'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Weather icon
                    Text(
                      hour['icon'],
                      style: const TextStyle(fontSize: 28),
                    ),

                    // Temperature
                    Text(
                      _getTemperature(hour['temp']),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Back button
        ElevatedButton.icon(
          onPressed: _toggleHourlyView,
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back to Current Weather"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
          ),
        ),

        const SizedBox(height: 30),
      ],
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