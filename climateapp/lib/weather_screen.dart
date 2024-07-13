import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui'; // Import this for ImageFilter
import 'package:climateapp/hourly_forecast.dart'; // Correct import
import 'package:climateapp/additional_info.dart'; // Correct import
import 'package:http/http.dart' as http;
import 'secret.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weatherData;

  @override
  void initState() {
    super.initState();
    weatherData = getCurrentWeather();
  }

  Future<Map<String, dynamic>> getCurrentWeather() async {
    String cityName = "London";
    try {
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$openWeatherAPIKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {'error': 'Failed to load weather data'};
      }
    } catch (e) {
      return {'error': 'Failed to load weather data'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weather App",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                weatherData = getCurrentWeather();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: weatherData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData || snapshot.data!.containsKey('error')) {
            return const Center(child: Text('Failed to load weather data'));
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];

          final currentTemp = currentWeatherData ['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];

          final currentHumidity = data['list'][0]['main']['humidity'];
          final currentWindSpeed = data['list'][0]['wind']['speed'];
          final currentPressure = data['list'][0]['main']['pressure'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Added blur effect
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '$currentTemp K',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Icon(
                              currentSky == 'Clouds' || currentSky == 'Rain'
                                  ? Icons.cloud
                                  : Icons.wb_sunny,
                              size: 64,
                            ),
                            Text(
                              currentSky,
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Hourly forecast',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < 5; i++)
                        hourly_forecast(
                          icon: data['list'][i]['weather'][0]['main'] == 'Clouds' ||
                                  data['list'][i]['weather'][0]['main'] == 'Rain'
                              ? Icons.cloud
                              : Icons.sunny,
                          time: DateTime.fromMillisecondsSinceEpoch(
                                  data['list'][i]['dt'] * 1000)
                              .toString()
                              .substring(11, 16), // Format time as HH:MM
                          temperature:
                              data['list'][i]['main']['temp'].toString(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AdditionalInfo(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value: currentHumidity.toString(),
                    ),
                    AdditionalInfo(
                      icon: Icons.air,
                      label: 'Wind speed',
                      value: currentWindSpeed.toString(),
                    ),
                    AdditionalInfo(
                      icon: Icons.beach_access,
                      label: 'Pressure',
                      value: currentPressure.toString(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
