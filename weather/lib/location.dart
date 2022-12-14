import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

var data;
bool isLoading = false;

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String? _currentAddress;
  Position? _currentPosition;
  bool isWeatherClick = false;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Page")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'LAT: ${_currentPosition?.latitude ?? ""}',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'LNG: ${_currentPosition?.longitude ?? ""}',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'ADDRESS: ${_currentAddress ?? ""}',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _getCurrentPosition,
                    child: const Text("Get Current Location"),
                  )
                ],
              ),
            ),
            Expanded(
                child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        getWeatherDetails();
                        setState(() {
                          isWeatherClick = true;
                        });
                      },
                      child: Text("Get Weather Details")),
                  SizedBox(
                    height: 10,
                  ),
                  isWeatherClick ? weather() : Container()
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  getWeatherDetails() async {
    isLoading = true;
    try {
      http.Response response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}&appid=316a7277a84229be3fcf54c1978e2037&units=metric'));

      if (response.statusCode == 200) {
        data = jsonDecode(response.body);
        print(data);

        // return data;
      } else {
        print(response.statusCode);
        // LocationPage();
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }
}

class weather extends StatefulWidget {
  const weather({super.key});

  @override
  State<weather> createState() => _weatherState();
}

class _weatherState extends State<weather> {
  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              color: Colors.blue,
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Weather Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                "Your co-ordinates = " +
                    data["coord"]["lon"].toString() +
                    ", " +
                    data["coord"]["lat"].toString(),
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              SizedBox(
                height: 7,
              ),
              Text(
                "Location = ${data["name"]}, ${data["sys"]["country"]}",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(
                height: 7,
              ),
              Text(
                "Weather = " + data["weather"][0]["main"].toString() ??
                    "" + ", " + data["weather"][0]["description"].toString() ??
                    "",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(
                height: 7,
              ),
              // Text(
              //   "Current Temperature = " +
              //       data["main"]["temp"].toString() +
              //       ", Feels Like = " +
              //       data["main"]["feels_like"].toString(),
              //   style: TextStyle(
              //     fontSize: 16,
              //   ),
              // ),
              // SizedBox(
              //   height: 7,
              // ),
              // Text(
              //   "Minimum Temp = " +
              //       data["main"]["temp_min"].toString() +
              //       ", Maximum Temp = " +
              //       data["main"]["temp_max"].toString(),
              //   style: TextStyle(
              //     fontSize: 16,
              //   ),
              // ),
              // SizedBox(
              //   height: 7,
              // ),
              // Text(
              //   "Pressure = " + data["main"]["pressure"].toString(),
              //   style: TextStyle(
              //     fontSize: 16,
              //   ),
              // ),
              // SizedBox(
              //   height: 7,
              // ),
              // Text(
              //   "Humidity = ${data["main"]["humidity"].toString()}",
              //   style: TextStyle(
              //     fontSize: 16,
              //   ),
              // ),
              // SizedBox(
              //   height: 7,
              // ),
              // Text(
              //   "Wind Speed = ${data["wind"]["speed"].toString()}, Wind direction: ${data["wind"]["deg"]}",
              //   style: TextStyle(fontSize: 16, fontFamily: "RaleWay"),
              // ),
            ],
          );
  }
}
