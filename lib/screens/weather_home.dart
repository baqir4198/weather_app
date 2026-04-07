import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  @override
  Widget build(BuildContext context) {
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
