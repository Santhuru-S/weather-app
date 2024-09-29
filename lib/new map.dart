import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class WeatherAPP extends StatefulWidget {
  const WeatherAPP({super.key});

  @override
  State<WeatherAPP> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherAPP> {
  Position? _currentPosition;
  String apiKey = '2668d09879277255af00abccfb23167d';
  String Alert = "";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permissions are permanently denied");
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
    return position;
  }

  Future<List<WeatherModel>> fetchNearbyWeather(double radius) async {
    if (_currentPosition == null) {
      throw Exception('Current position is not available');
    }

    List<LatLng> nearbyPoints = _getNearbyPoints(_currentPosition!, radius);
    List<WeatherModel> weatherData = [];

    for (LatLng point in nearbyPoints) {
      WeatherModel weather =
          await fetchWeatherData(point.latitude, point.longitude);
      weatherData.add(weather);
    }

    return weatherData;
  }

  Future<WeatherModel> fetchWeatherData(double lat, double lon) async {
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return WeatherModel.fromMap(data);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  List<LatLng> _getNearbyPoints(Position position, double radius) {
    double lat = position.latitude;
    double lon = position.longitude;

    double latRadius = radius / 111320;
    double lonRadius = radius / (111320 * cos(lat * pi / 180));

    // Create points around the current position within the given radius
    List<LatLng> points = [
      LatLng(lat + latRadius, lon),
      LatLng(lat - latRadius, lon),
      LatLng(lat, lon + lonRadius),
      LatLng(lat, lon - lonRadius),
      LatLng(lat + latRadius / sqrt(2), lon + lonRadius / sqrt(2)),
      LatLng(lat + latRadius / sqrt(2), lon - lonRadius / sqrt(2)),
      LatLng(lat - latRadius / sqrt(2), lon + lonRadius / sqrt(2)),
      LatLng(lat - latRadius / sqrt(2), lon - lonRadius / sqrt(2)),
    ];

    return points;
  }

  void _warningMessage(List<WeatherModel>weatherData){
    bool Rainy = weatherData.any((weather)=>weather.icon.contains('9') ||
        weather.icon.contains('10')
    );
    bool Hot = weatherData.any((weather)=> double.parse(weather.temp)>35);
    bool Cool = weatherData.any((weather)=> double.parse(weather.temp)<5);

    if (Rainy) {
      setState(() {
        Alert = 'Warning: Rain is expected in the area. Please take precautions.';
      });
    } else if (Hot) {
      setState(() {
        Alert = 'Warning: High temperatures detected. Stay hydrated and avoid the sun.';
      });
    } else if (Cool) {
      setState(() {
        Alert = 'Warning: Cold temperatures detected. Dress warmly and stay safe.';
      });
    } else {
      setState(() {
        Alert = 'Weather is normal. No warnings at this time.';
      });
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('15 km Surronding weather'),
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<WeatherModel>>(
              future: fetchNearbyWeather(15000),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No data available"));
                } else {
                  return Column(
                    children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            Alert,
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView(
                          children: snapshot.data!.map((weather) {
                            Color cityNameColor = Colors.black;
                            if (weather.icon.contains('09') ||
                                weather.icon.contains('10')) {
                              cityNameColor = Colors.blue;
                            } else if (weather.icon.contains('11')) {
                              cityNameColor = Colors.deepPurple;
                            } else if (weather.icon.contains('13')) {
                              cityNameColor = Colors.lightBlue;
                            } else if (weather.icon.contains('50')) {
                              cityNameColor = Colors.grey;
                            }
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                    "http://openweathermap.org/img/wn/${weather.icon}.png"),
                              ),
                              title: Text("${weather.cityName}, ${weather.country}"),
                              subtitle: Text(
                                  "Temperature: ${weather.temp}°C, Humidity: ${weather.humidity}%",
                                    style: TextStyle(color: cityNameColor),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
    );
  }
}

class WeatherModel {
  final String temp;
  final String humidity;
  final String country;
  final String cityName;
  String icon;

  WeatherModel(
      {required this.temp,
      required this.humidity,
      required this.country,
      required this.cityName,
      required this.icon});

  factory WeatherModel.fromMap(Map<String, dynamic> map) {
    return WeatherModel(
      temp: (map['main']['temp'] - 273.15).toStringAsFixed(2),
      humidity: map['main']['humidity'].toString(),
      country: map['sys']['country'].toString(),
      cityName: map['name'].toString(),
      icon: map['weather'][0]['icon'],
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
