import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' show Lottie;

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

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  _loadWeather() async {
    try {
      final data = await _weatherService.fetchLocalWeather();

      // Get coordinates from the data we just fetched
      double lat = data['latitude'];
      double lon = data['longitude'];

      // Convert those coordinates to a City Name
      String city = await _weatherService.getCityName(lat, lon);

      setState(() {
        _weatherData = data;
        _cityName = city; // Update the city name
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() { _isLoading = false; });
    }
  }

  String getWeatherAnimation(String? condition1){
    if(condition1 == null) return 'assets/sun.json';
    switch(condition1.toLowerCase()){
      case 'clear sky':
        return 'assets/sun.json';
      case 'partly cloudy':
        return 'assets/partly_cloudy.json';
      case 'cloudy':
        return 'assets/cloudy.json';
      case 'raining':
        return 'assets/rainy.json';
      case 'drizzle':
        return 'assets/drizzling.json';
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
    final wind  = current['wind_speed_10m'];
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration:  const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E335A),Color(0xFF1C1B33)]
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_cityName,style: TextStyle(fontSize: 42,fontWeight: FontWeight.w500),),
            Lottie.asset(
              getWeatherAnimation(condition),
              width: 200,
              height: 200,
            ),
            Text("$temp°", style: const TextStyle(fontSize: 80)),
            Text(condition, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 40,),
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
                  _weatherDetail("Humidity","$humidity%"),
                  _weatherDetail("Wind","$wind km/h"),
                  _weatherDetail("Feels Like","${_weatherData!['current']['apparent_temperature']}°"),
                ]
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _weatherDetail(String label,String value){
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey,fontSize: 12)),
        const SizedBox(height: 5,),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
