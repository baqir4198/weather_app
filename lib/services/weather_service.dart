import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String baseUrl = "https://api.open-meteo.com/v1/forecast";

  Future<Map<String,dynamic>> fetchLocalWeather()async{
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied){
        return Future.error("Location permissions are denied");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // The user clicked "Don't ask again"
      return Future.error('Location permissions are permanently denied.');
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low
    );
      final response = await http.get(Uri.parse(
        '$baseUrl?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&timezone=auto'
      ));
    if(response.statusCode == 200){
      return jsonDecode(response.body);
    }else{
      throw Exception("Could not fetch weather data");
    }
  }
  String interpretCode(int code){
    if(code == 0) return "Clear Sky";
    if(code <= 3) return "Partly Cloudy";
    if(code >= 51 && code <= 67) return "Raining";
    if(code >= 71 && code <= 77) return "Snowing";
    return "Cloudy";

  }
  Future<String> getCityName(double lat, double lon) async{
    try{
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if(placemarks.isNotEmpty){
        return placemarks[0].locality ?? "Unknown City";
      }
      return "City not found";
    }catch(e){
      return "Location Error";
    }
  }
}