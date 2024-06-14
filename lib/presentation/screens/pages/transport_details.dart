// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gradution_project2/presentation/screens/pages/transport_details_page.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class TransportDetails extends StatefulWidget {
  const TransportDetails({super.key});

  @override
  _TransportDetailsState createState() => _TransportDetailsState();
}

class _TransportDetailsState extends State<TransportDetails> {
  TextEditingController addNameController = TextEditingController();
  bool isSearching = false;
  Map<String, List<QueryDocumentSnapshot>> lineAvailableMap = {};
  Map<String, String> stationNameMap = {};
  Map<String, bool> expansionTileState = {};
  bool dataLoaded = false;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    fetchData();
    checkLocationPermission();

    _getCurrentLocation();
  }

  Future<void> fetchData() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final snapshot = await FirebaseFirestore.instance
          .collection('المواقف')
          .orderBy('timestamp', descending: true)
          .get();
      print('Data fetched successfully.');

      List<Map<String, dynamic>> stationsWithDistance = [];

      for (final doc in snapshot.docs) {
        final lineData = await getLineAvailable(doc.id);
        GeoPoint location = doc['location'];
        double distance = await _calculateDistance(currentPosition.latitude,
            currentPosition.longitude, location.latitude, location.longitude);
        stationsWithDistance.add({
          'id': doc.id,
          'name': doc['name'],
          'distance': distance,
        });
        lineAvailableMap[doc.id] = lineData;
        stationNameMap[doc.id] = doc['name'];
        expansionTileState[doc.id] = true;
      }

      stationsWithDistance
          .sort((a, b) => a['distance'].compareTo(b['distance']));

      lineAvailableMap.clear();
      stationNameMap.clear();
      expansionTileState.clear();

      for (var station in stationsWithDistance) {
        lineAvailableMap[station['id']] = await getLineAvailable(station['id']);
        stationNameMap[station['id']] = station['name'];
        expansionTileState[station['id']] = true;
      }

      setState(() {
        dataLoaded = true;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<double> _calculateDistance(double userLat, double userLong,
      double stationLat, double stationLong) async {
    double distanceInMeters =
        Geolocator.distanceBetween(userLat, userLong, stationLat, stationLong);
    return distanceInMeters;
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

  Future<void> checkLocationPermission() async {
    PermissionStatus permissionStatus = await Permission.location.status;

    if (permissionStatus != PermissionStatus.granted) {
      PermissionStatus newPermissionStatus =
          await Permission.location.request();

      if (newPermissionStatus != PermissionStatus.granted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('تفعيل الموقع'),
              content: const Text(
                  'يرجى تفعيل الصلاحية للوصول إلى الموقع واستخدام هذه الميزة'),
              actions: <Widget>[
                TextButton(
                  child: const Text('إغلاق'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('فتح الإعدادات'),
                  onPressed: () async {
                    openAppSettings();
                  },
                ),
              ],
            );
          },
        );
      }
    }
    _getCurrentLocation();

    // إذا كانت الصلاحية ممنوحة، نقوم بتنفيذ الكود الخاص بجلب البيانات
    fetchData();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentPosition = position;
      });
    } catch (e) {}
  }

  Future<void> _openInMap(double latitude, double longitude) async {
    String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  void _getPublicTransportForStation(String stationId, String lineName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransportDetailsPage(
          stationId: stationId,
          lineName: lineName,
          currentPosition: currentPosition!,
        ),
      ),
    );
  }

  IconData _getTransportIcon(Map<String, dynamic> step) {
    if (step.containsKey('transit_details')) {
      final transitDetails = step['transit_details'];
      final vehicleType = transitDetails['line']['vehicle']['type'];

      switch (vehicleType) {
        case 'BUS':
          return Icons.directions_bus;
        case 'WALKING':
          return Icons.directions_walk;
        case 'RAIL':
          return Icons.train;
        default:
          return Icons.directions;
      }
    } else {
      return Icons.directions;
    }
  }

  String _stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: const Text("تفاصيل الذهاب الى وجهتك"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.end,
                    cursorColor: Colors.blue,
                    controller: addNameController,
                    onChanged: (value) {
                      setState(() {
                        isSearching = true;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "ابحث عن وجهتك",
                      hintStyle: TextStyle(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
            Expanded(
              child: dataLoaded
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: lineAvailableMap.length,
                      itemBuilder: (BuildContext context, int index) {
                        final MapEntry<String, List<QueryDocumentSnapshot>>
                            entry = lineAvailableMap.entries.elementAt(index);
                        final stationId = entry.key;
                        final List<QueryDocumentSnapshot> lineAvailable =
                            entry.value;

                        final stationName = stationNameMap[stationId] ?? '';

                        final filteredLines = lineAvailable
                            .where((line) => line['nameLine']
                                .toString()
                                .contains(addNameController.text.trim()))
                            .toList();

                        final hasSearchResults = filteredLines.isNotEmpty;

                        final hasLines = lineAvailable.isNotEmpty;

                        if (!hasLines) {
                          return const SizedBox();
                        }

                        if (hasSearchResults) {
                          return ExpansionTile(
                            iconColor: Colors.blue,
                            title: Text("موقف $stationName"),
                            initiallyExpanded:
                                expansionTileState[stationId] ?? false,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                expansionTileState[stationId] = expanded;
                              });
                            },
                            children: [
                              Column(
                                children: filteredLines
                                    .map((line) => ListTile(
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("خط ${line['nameLine']}"),
                                              const Text("اضغط للتفاصيل")
                                            ],
                                          ),
                                          subtitle: Text(
                                              "سعر الخط: ${line['priceLine']}"),
                                          onTap: () {
                                            _getPublicTransportForStation(
                                                stationId, line['nameLine']);
                                          },
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(
                                height: 30,
                              )
                            ],
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    )
                  : Center(
                      child: Column(
                      children: [
                        Lottie.asset("asset/images/splash.json"),
                        const CircularProgressIndicator(
                          color: Colors.blue,
                        ),
                        const Text(
                            "انتظر قليلا جار ترتيب المواقف من حيث الاقرب لك...")
                      ],
                    )),
            )
          ],
        ),
      ),
    );
  }
}
