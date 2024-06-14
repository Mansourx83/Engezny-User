import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportDetailsPage extends StatefulWidget {
  final String stationId;
  final String lineName;
  final Position currentPosition;

  const TransportDetailsPage({
    super.key,
    required this.stationId,
    required this.lineName,
    required this.currentPosition,
  });

  @override
  _TransportDetailsPageState createState() => _TransportDetailsPageState();
}

class _TransportDetailsPageState extends State<TransportDetailsPage> {
  GoogleMapController? _mapController;
  final List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};
  late LatLng _initialPosition;
  late LatLng _destinationPosition;
  bool _isMapInitialized = false;
  List<dynamic> _routes = [];
  int _selectedRouteIndex = -1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePositions();
    _fetchTransportDetails().then((data) {
      setState(() {
        _routes = data['routes'];
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching transport details: $error');
    });
  }

  void _initializePositions() async {
    try {
      GeoPoint stationLocation = (await FirebaseFirestore.instance
              .collection('المواقف')
              .doc(widget.stationId)
              .get())
          .get('location');

      _destinationPosition =
          LatLng(stationLocation.latitude, stationLocation.longitude);
      _initialPosition = LatLng(
          widget.currentPosition.latitude, widget.currentPosition.longitude);

      setState(() {
        _isMapInitialized = true;
      });
    } catch (e) {
      print('Error initializing positions: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchTransportDetails() async {
    try {
      GeoPoint stationLocation = (await FirebaseFirestore.instance
              .collection('المواقف')
              .doc(widget.stationId)
              .get())
          .get('location');

      const apiKey =
          'AIzaSyAy0t9jzqEs4mM4QHHWlrZf8lizDeFNE-s'; // Replace with your API key
      const apiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
      const language = 'en';

      final response = await http.get(Uri.parse(
          '$apiUrl?key=$apiKey&origin=${widget.currentPosition.latitude},${widget.currentPosition.longitude}&destination=${stationLocation.latitude},${stationLocation.longitude}&mode=transit&language=$language&alternatives=true'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Routes fetched successfully: ${data['routes']}');
        return data;
      } else {
        throw Exception('Failed to load public transport data');
      }
    } catch (e) {
      print('Error getting public transport data: $e');
      rethrow;
    }
  }

  void _setPolylines(String encodedPolyline) {
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);

      _polylineCoordinates.clear();
      for (var point in result) {
        _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('polyline'),
          color: Colors.blue,
          width: 5,
          points: _polylineCoordinates,
        ));
      });
    } catch (e) {
      print('Error setting polylines: $e');
    }
  }

  void _selectRoute(int routeIndex) {
    setState(() {
      _selectedRouteIndex = routeIndex;
    });
    final selectedRoute = _routes[routeIndex];
    _setPolylines(selectedRoute['overview_polyline']['points']);
  }

  void _showAllRoutesOnMap() {
    _polylines.clear();
    for (var route in _routes) {
      _setPolylines(route['overview_polyline']['points']);
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_selectedRouteIndex == -1) return;

    final route = _routes[_selectedRouteIndex];
    final legs = route['legs'];
    final origin = legs[0]['start_location'];
    final destination = legs[legs.length - 1]['end_location'];

    String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&origin=${origin['lat']},${origin['lng']}&destination=${destination['lat']},${destination['lng']}&travelmode=transit';

    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  Widget _buildRouteList() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _showAllRoutesOnMap,
          child: const Text('عرض على الخريطة'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _routes.length,
            itemBuilder: (BuildContext context, int routeIndex) {
              final route = _routes[routeIndex];
              final legs = route['legs'];
              return ListTile(
                title: Text(
                    "Route ${routeIndex + 1}: ${legs[0]['duration']['text']}, ${legs[0]['distance']['text']}"),
                onTap: () => _selectRoute(routeIndex),
                selected: _selectedRouteIndex == routeIndex,
                selectedTileColor: Colors.blue.withOpacity(0.2),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteDetails() {
    if (_selectedRouteIndex == -1) return Container();

    final route = _routes[_selectedRouteIndex];
    final legs = route['legs'];

    return Column(
      children: [
        ElevatedButton(
          onPressed: _openInGoogleMaps,
          child: const Text('فتح في جوجل ماب'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: legs.length,
            itemBuilder: (BuildContext context, int legIndex) {
              final leg = legs[legIndex];
              final steps = _flattenSteps(leg['steps']);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Leg ${legIndex + 1}: ${leg['duration']['text']}, ${leg['distance']['text']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Column(
                    children: List.generate(steps.length, (stepIndex) {
                      final step = steps[stepIndex];
                      final stepTitle = step.containsKey('html_instructions')
                          ? _stripHtmlIfNeeded(step['html_instructions'])
                          : 'No instructions';
                      final stepDuration = step.containsKey('duration')
                          ? step['duration']['text']
                          : 'Unknown duration';
                      final stepDistance = step.containsKey('distance')
                          ? step['distance']['text']
                          : 'Unknown distance';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: Icon(
                            _getTransportIcon(step),
                            color: Colors.blue,
                          ),
                          title: Text(stepTitle),
                          subtitle: Text('$stepDuration, $stepDistance'),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: Text("تفاصيل خط ${widget.lineName}"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: !_isMapInitialized
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _initialPosition,
                      zoom: 14.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: _initialPosition,
                        infoWindow: const InfoWindow(title: 'موقعك الحالي'),
                      ),
                      Marker(
                        markerId: const MarkerId('destination'),
                        position: _destinationPosition,
                        infoWindow: InfoWindow(title: widget.lineName),
                      ),
                    },
                    polylines: _polylines,
                  ),
          ),
          Expanded(
            flex: 1,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _routes.isEmpty
                    ? const Center(child: Text('No routes available'))
                    : _buildRouteSelectionAndDetails(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSelectionAndDetails(BuildContext context) {
    return Column(
      children: [
        if (_selectedRouteIndex == -1) Expanded(child: _buildRouteList()),
        if (_selectedRouteIndex != -1)
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildRouteDetails()),
              ],
            ),
          ),
      ],
    );
  }

  List<dynamic> _flattenSteps(List<dynamic> steps) {
    List<dynamic> flattenedSteps = [];
    for (var step in steps) {
      flattenedSteps.add(step);
      if (step.containsKey('steps')) {
        flattenedSteps.addAll(step['steps']);
      }
    }
    return flattenedSteps;
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
        case 'SUBWAY':
        case 'TRAM':
          return Icons.directions_railway;
        default:
          return Icons.directions;
      }
    } else if (step['travel_mode'] == 'WALKING') {
      return Icons.directions_walk;
    } else {
      return Icons.directions;
    }
  }

  String _stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
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
}
