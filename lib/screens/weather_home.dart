import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/weather_service.dart';

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
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
      print("Requesting location..."); // Debugging line 1
      final data = await _weatherService.fetchLocalWeather();
      print("Data received: $data");    // Debugging line 2
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR FETCHING WEATHER: $e"); // Check your console for this!
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_isLoading){
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            const Text("Current Location",style: TextStyle(fontSize: 32),),
            Text("$temp°", style: const TextStyle(fontSize: 80)),
            Text(condition, style: const TextStyle(color: Colors.grey)),

            const Text(
              "Lahore",
              style: TextStyle(fontSize: 32,fontWeight: FontWeight.w300),
            ),
            const Text(
              "24°",
              style: TextStyle(fontSize: 80,fontWeight: FontWeight.bold),
            ),
            const Text(
              "PARTLY CLOUDY",
              style: TextStyle(fontSize: 16, color: Colors.grey, letterSpacing: 1.5),
            ),
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
                  _weatherDetail("Humidity","62%"),
                  _weatherDetail("Wind","12 km/h"),
                  _weatherDetail("Feels Like","26°"),
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
