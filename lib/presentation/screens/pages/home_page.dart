import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gradution_project2/bussines_logic/cubit/phone_auth_cubit.dart';
import 'package:gradution_project2/constant/strings.dart';
import 'package:gradution_project2/presentation/screens/components/drop_down.dart';
import 'package:gradution_project2/presentation/widgets/constant_widget.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StreamController<double> _fadeController = StreamController<double>();

  List<QueryDocumentSnapshot>? stationName;
  Map<String, List<QueryDocumentSnapshot>> lineAvailableMap = {};
  String? selectedCity;
  bool isLoading = false;

  late maps.GoogleMapController _mapController;
  late maps.LatLng _currentLocation = const maps.LatLng(0.0, 0.0);
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    fetchData();
    _markers = <Marker>{};
  }

  @override
  void dispose() {
    _fadeController.close();
    super.dispose();
  }

  Future<void> fetchData() async {
    await getStationName();
    await fetchLineDataForEachStation();
  }

  Future<void> getStationName() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection("المواقف").get();
    stationName = querySnapshot.docs;
  }

  Future<void> fetchLineDataForEachStation() async {
    if (stationName != null) {
      for (var station in stationName!) {
        await fetchDataForSelectedCity(station.id);
      }
    }
  }

  Future<void> fetchDataForSelectedCity(String cityId) async {
    try {
      final lineData = await getLineAvailable(cityId);
      if (mounted) {
        lineAvailableMap[cityId] = lineData;
        setState(() {});
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        animType: AnimType.rightSlide,
        title: '',
        desc: "هناك مشكله",
        btnOkOnPress: () {},
      ).show();
    }
  }

  Future<List<QueryDocumentSnapshot>> getLineAvailable(String stationId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("المواقف")
          .doc(stationId)
          .collection("line")
          .get();

      return querySnapshot.docs;
    } catch (e) {
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> getCarDataForLine(
      String stationId, String lineId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("المواقف")
        .doc(stationId)
        .collection("line")
        .doc(lineId)
        .collection("car")
        .orderBy("timestamp", descending: false)
        .get();

    return querySnapshot.docs;
  }

  Future<Map<String, dynamic>> getCarData(String carNumber) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('AllCars')
        .where('numberOfCar', isEqualTo: carNumber)
        .get();

    return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.data() : {};
  }

  void refreshData() {
    setState(() {
      stationName = null;
      lineAvailableMap.clear();
      selectedCity = null;
    });
    fetchData();
  }

  Future<void> launchMap(String name, GeoPoint location) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showEnableLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showEnableLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (mounted) {
          if (position.latitude != 0.0 && position.longitude != 0.0) {
            setState(() {
              _currentLocation =
                  maps.LatLng(position.latitude, position.longitude);
              _markers.add(
                maps.Marker(
                  markerId: const maps.MarkerId("currentLocation"),
                  position: _currentLocation,
                  infoWindow: const maps.InfoWindow(title: "Your Location"),
                ) as Marker,
              );
            });
          } else {}
        }
      } else {
        await _showEnableLocationPermissionDialog();
      }
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  Future<void> _showEnableLocationServiceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text("تفعيل خدمة الموقع")),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  "يرجي تفعيل خدمة الموقع للحصول علي اقرب موقف بالنسبه لك",
                  style: TextStyle(),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50)),
                    onPressed: () async {
                      if (await Geolocator.openLocationSettings()) {
                        await getCurrentLocation();
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "تفعيل الموقع",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("حسنا", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEnableLocationPermissionDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تفعيل الصلاحيات"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "الوصول إلى الموقع غير مسموح به. يرجى تفعيل الصلاحيات للاستمرار."),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  Navigator.of(context).pop();
                },
                child: const Text("فتح إعدادات التطبيق"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("إلغاء"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: refreshData,
          icon: const Icon(Icons.refresh),
        ),
        actions: [
          BlocProvider(
            create: (context) => PhoneAuthCubit(),
            child: IconButton(
              onPressed: () async {
                final phoneAuthCubit = PhoneAuthCubit();
                final googleSignIn = GoogleSignIn();
                try {
                  await googleSignIn.disconnect();
                } catch (error) {}
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (error) {}
                await phoneAuthCubit.logOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  choseLogin,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        onPressed: () async {
          setState(() {
            isLoading = true;
          });
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: Colors.transparent,
                  ),
                  Center(
                      child: Column(
                    children: [
                      Lottie.asset("asset/images/splash.json"),
                      const CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    ],
                  )),
                ],
              );
            },
          );
          await getCurrentLocation();
          if (_currentLocation.latitude != 0.0 &&
              _currentLocation.longitude != 0.0) {
            Navigator.of(context).pop();
            _showNearestStationDialog();
          }
          setState(() {
            isLoading = false;
          });
        },
        label: const Text("اقرب موقف لك"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: StreamBuilder<double>(
            stream: _fadeController.stream,
            builder: (context, snapshot) {
              double fadeValue = snapshot.data ?? 1.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height: 200,
                    child: ConstantWidget(),
                  ),
                  const SizedBox(height: 20),
                  if (stationName != null && stationName!.isNotEmpty)
                    MyDropdownButton(
                      itemPrefix: 'موقف',
                      hint: "اختر الموقف",
                      stationName: stationName!
                          .map<String>((doc) => doc['name'] as String)
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCity = newValue;
                        });
                      },
                    ),
                  const SizedBox(height: 20),
                  for (var station in stationName ?? [])
                    if (selectedCity == station["name"])
                      Column(
                        children: [
                          if (lineAvailableMap.containsKey(station.id)) ...[
                            const SizedBox(height: 10),
                            Text(
                              "الخطوط التي توجد في موقف ${station["name"]} (${lineAvailableMap[station.id]!.length} خط)",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue),
                              onPressed: () {
                                launchMap(station["name"], station["location"]);
                              },
                              child: Text(
                                "موقع موقف ${station["name"]}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            for (var line
                                in lineAvailableMap[station.id] ?? []) ...[
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.grey[200],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            "${line['nameLine']}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_back),
                                          Text(
                                            "$selectedCity",
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      FutureBuilder(
                                        future: getCarDataForLine(
                                            station.id, line.id),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator(
                                              color: Colors.blue,
                                            );
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                "Error: ${snapshot.error}");
                                          } else if (!snapshot.hasData ||
                                              (snapshot.data as List).isEmpty) {
                                            return const Text(
                                                "لا توجد عربيات متاحه الان");
                                          } else {
                                            List<dynamic> carsData =
                                                snapshot.data as List;

                                            int numberOfAvailableCars =
                                                carsData.length;
                                            var firstCarData =
                                                carsData.isNotEmpty
                                                    ? carsData[0]
                                                    : null;

                                            if (firstCarData != null) {
                                              String carNumber =
                                                  firstCarData['numberOfCar'];
                                              return Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      Text(
                                                        "عدد العربيات المتاحه: $numberOfAvailableCars",
                                                        style: const TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                      Text(
                                                        "سعر الاجره: ${line['priceLine']}ج",
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      Text(
                                                        "نمرة السيارة: ${firstCarData['numberOfCar']}",
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                          ),
                                                          FutureBuilder(
                                                            future: getCarData(
                                                                carNumber),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .waiting) {
                                                                return const CircularProgressIndicator(
                                                                    color: Colors
                                                                        .blue);
                                                              } else if (snapshot
                                                                  .hasError) {
                                                                return Text(
                                                                    "Error: ${snapshot.error}");
                                                              } else {
                                                                var carRatingData =
                                                                    snapshot.data
                                                                        as Map<
                                                                            String,
                                                                            dynamic>;
                                                                double?
                                                                    averageRating;
                                                                try {
                                                                  averageRating =
                                                                      double
                                                                          .parse(
                                                                    carRatingData['averageRating']
                                                                            ?.toString() ??
                                                                        '0.0',
                                                                  );
                                                                } catch (e) {
                                                                  averageRating =
                                                                      0.0;
                                                                }

                                                                return Text(
                                                                  "التقييم المتوسط: ${averageRating.toStringAsFixed(1) ?? '0.0'}",
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              );
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ],
                        ],
                      ),
                  const SizedBox(
                    height: 50,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Map<String, double>> getDistanceAndDuration(
      maps.LatLng origin, maps.LatLng destination, String mode) async {
    const apiKey = 'AIzaSyAy0t9jzqEs4mM4QHHWlrZf8lizDeFNE-s';
    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=${origin.latitude},${origin.longitude}&destinations=${destination.latitude},${destination.longitude}&mode=$mode&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print(response.request);
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final elements = data['rows'][0]['elements'] as List<dynamic>;
        if (elements.isNotEmpty) {
          final distanceData = elements[0]['distance'];
          final durationData = elements[0]['duration'];
          final distance =
              distanceData != null ? distanceData['value'] as int : 0;
          final duration =
              durationData != null ? durationData['value'] as int : 0;
          return {'distance': distance / 1000.0, 'duration': duration / 60.0};
        }
      }
    }
    return {'distance': 0.0, 'duration': 0.0};
  }

  Future<void> _showNearestStationDialog() async {
    if (stationName == null || stationName!.isEmpty) {
      return;
    }

    List<Map<String, dynamic>> modes = [
      {"name": "المشي", "icon": Icons.directions_walk},
      {"name": "السيارة", "icon": Icons.directions_car},
      {"name": "الموتوسيكل", "icon": Icons.motorcycle_rounded},
    ];

    String? selectedMode = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text(
            'اختر نوع المواصلات',
            textAlign: TextAlign.center,
          ),
          children: modes.map((mode) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, mode["name"]);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    mode["icon"],
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  Text(mode["name"]),
                ],
              ),
            );
          }).toList(),
        );
      },
    );

    if (selectedMode != null) {
      String modeForAPI;
      if (selectedMode == "المشي") {
        modeForAPI = "walking";
      } else if (selectedMode == "السيارة") {
        modeForAPI = "driving";
      } else {
        modeForAPI = "motorcycle";
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
              child: Column(
            children: [
              Lottie.asset("asset/images/splash.json"),
              const CircularProgressIndicator(
                color: Colors.blue,
              ),
              Text("جار حساب اقرب موقف بالنسبه ل $selectedMode"),
            ],
          ));
        },
      );

      double minDistance = double.infinity;
      int minDuration = 0;
      QueryDocumentSnapshot? nearestStation;

      for (var station in stationName!) {
        GeoPoint stationLocation = station['location'];
        Map<String, double> data = await getDistanceAndDuration(
          maps.LatLng(_currentLocation.latitude, _currentLocation.longitude),
          maps.LatLng(stationLocation.latitude, stationLocation.longitude),
          modeForAPI,
        );

        double distance = data['distance'] ?? 0.0;
        double duration = data['duration'] ?? 0.0;

        if (distance < minDistance) {
          minDistance = distance;
          minDuration = duration.round();
          nearestStation = station;
        }
      }

      Navigator.pop(context);

      if (nearestStation != null) {
        final distanceInKm = minDistance;
        final distanceInMeters = minDistance * 1000;

        if (await Geolocator.isLocationServiceEnabled()) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  "أقرب موقف",
                  textAlign: TextAlign.center,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 30,
                          ),
                          Icon(
                            _getIconForMode(selectedMode),
                            color: Colors.blue,
                            size: 30,
                          ),
                          Flexible(
                            flex: 2,
                            child: Text(
                              " الموقف الأقرب إليك بالنسبه ل $selectedMode هو: ${nearestStation?['name']}",
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("المسافة: ${distanceInKm.toStringAsFixed(1)} كم"),
                      Text("${distanceInMeters.toStringAsFixed(1)} متر"),
                      const SizedBox(height: 10),
                      Text("الوقت المقدر تقريبا: $minDuration دقيقة"),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("حسنًا",
                        style: TextStyle(color: Colors.black)),
                  ),
                  TextButton(
                    onPressed: () {
                      launchMap(
                          nearestStation?['name'], nearestStation?['location']);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "عرض الموقع على الخريطة",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("أقرب موقف"),
              content: const Text("لا يمكن العثور على المواقف القريبة."),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("حسنًا"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  IconData _getIconForMode(String mode) {
    switch (mode) {
      case "المشي":
        return Icons.directions_walk;
      case "السيارة":
        return Icons.directions_car;
      case "الموتوسيكل":
        return Icons.motorcycle_rounded;
      default:
        return Icons.directions_walk; // Default icon
    }
  }
}
