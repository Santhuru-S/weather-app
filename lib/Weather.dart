import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as sky;
import 'package:intl/intl.dart';
import 'package:weather/new%20map.dart';

class Weather extends StatefulWidget {
  const Weather({super.key});

  @override
  State<Weather> createState() => _WeatherState();
}

class _WeatherState extends State<Weather> {
  Position? _currentPosition;
  TextEditingController latController = TextEditingController();
  TextEditingController lonController = TextEditingController();
  TextEditingController districtController = TextEditingController();

  String district = "Chennai";
  String lat = "13.0827";
  String lon = "80.2707";
  String apiKey =
      '2668d09879277255af00abccfb23167d'; // Replace with your OpenWeatherMap API key

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future _getCurrentLocation() async {
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
      latController.text = position.latitude.toString();
      lonController.text = position.longitude.toString();
    });
  }

  Future<MapWeather> fetchWeather() async {
    final res = await sky.get(Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$district&lat=$lat&lon=$lon&appid=$apiKey"));

    if (res.statusCode == 200) {
      return MapWeather.fromMap(jsonDecode(res.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Weather"),
        actions: [
          TextButton(onPressed: (){
            Navigator.push(context,
                MaterialPageRoute(builder: (context)=>WeatherAPP())
            );
          }, child:Text("NearWeather") ),
          ElevatedButton(
              onPressed: () async {
                Position latLong = await _getCurrentLocation();
                setState(() {
                  _currentPosition = latLong;
                  latController.text = latLong.latitude.toString();
                  lonController.text = latLong.longitude.toString();
                });
              },
              child: Text("Get Location")),

        ],
      ),
      body: FutureBuilder<MapWeather>(
        future: fetchWeather(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            return Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("assets/sun.jpg"),
                          fit: BoxFit.fill)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaY: 9,
                      sigmaX: 9,
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(0),
                    ),
                  ),
                ),
                // Positioned(
                //     bottom: 10,
                //     child: Container(
                //       height: 230,
                //       width: 410,
                //       decoration: BoxDecoration(
                //           color: Colors.white,
                //           borderRadius: BorderRadius.only(
                //             topLeft: Radius.circular(170),
                //             topRight: Radius.circular(170),
                //           )),
                //     )),
                Positioned(
                  bottom: 20,
                  child: Container(
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: TextFormField(
                            controller: districtController,
                            decoration: InputDecoration(
                              suffixIcon: TextButton(
                                  // style: ElevatedButton.styleFrom(
                                  //     side: BorderSide(color: Colors.black),
                                  //     // shape: BeveledRectangleBorder(
                                  //     //     borderRadius:
                                  //     //         BorderRadius.circular(2))
                                  //                ),
                                  onPressed: () {
                                    setState(() {
                                      district = districtController.text;
                                    });
                                  },
                                  child: Text("Enter")),
                              hintText: "Enter district",
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: CupertinoColors.systemBlue,
                                      width: 2)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: latController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder()),
                          ),
                        )),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: lonController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder()),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                Positioned(
                    top: 220,
                    left: 130,
                    child: Column(
                      children: [
                        Text("${snapshot.data!.humidity}\t%",
                            style: TextStyle(
                                color: Colors.white, fontSize: 20)),
                        Text(
                          "humidity",
                          style: TextStyle(
                              color: CupertinoColors.white, fontSize: 20),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(100)),
                          height: 100,
                          width: 100,
                          child: Icon(
                            Icons.water_drop_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )),
                Positioned(
                    top: 250,
                    left: 245,
                    child: Column(
                      children: [
                        Text("${snapshot.data!.deg}°",
                            style: TextStyle(
                                color: Colors.white, fontSize: 20)),
                        Text(
                          "degree",
                          style: TextStyle(
                              color: CupertinoColors.white, fontSize: 20),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(100)),
                          height: 100,
                          width: 100,
                          child: Icon(
                            Icons.rotate_90_degrees_ccw,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ],
                    )),
                Positioned(
                    top: 250,
                    left: 20,
                    child: Column(
                      children: [
                        Text("${snapshot.data!.speed}\tkm/h",
                            style: TextStyle(
                                color: Colors.white, fontSize: 20)),
                        Text(
                          "speed",
                          style: TextStyle(
                              color: CupertinoColors.white, fontSize: 20),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(100)),
                          height: 100,
                          width: 100,
                          child: Icon(
                            CupertinoIcons.wind,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ],
                    )),
                Positioned(
                  top: 100,
                  left: 100,
                  child: Column(
                    children: [
                      Text(
                        "${(double.parse(snapshot.data!.temp) - 221.00).toStringAsFixed(2)}°F",
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "${(double.parse(snapshot.data!.temp) - 272.00).toStringAsFixed(2)}°C",
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Positioned(
                    left: 100,
                    top: 20,
                    child: Column(
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy h.mm a')
                              .format(DateTime.now()),
                          style:
                              TextStyle(color: Colors.white, fontSize: 25),
                        ),
                        Text(
                          "${snapshot.data!.country}",
                          style:
                              TextStyle(fontSize: 30, color: Colors.white),
                        ),
                      ],
                    )),
              ],
            );
          } else {
            return Center(child: Text("No data available"));
          }
        },
      ),
    );
  }
}

class MapWeather {
  final String temp;
  final String humidity;
  final String deg;
  final String speed;
  final String country;

  MapWeather(
      {required this.temp,
      required this.humidity,
      required this.deg,
      required this.speed,
      required this.country});

  factory MapWeather.fromMap(Map<String, dynamic> map) {
    return MapWeather(
      temp: map['main']['temp'].toString(),
      humidity: map['main']['humidity'].toString(),
      deg: map['wind']['deg'].toString(),
      speed: map['wind']['speed'].toString(),
      country: map['sys']['country'].toString(),
    );
  }
}
