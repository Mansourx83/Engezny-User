import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteDetailsPage extends StatefulWidget {
  final dynamic routeData;

  const RouteDetailsPage({super.key, required this.routeData});

  @override
  _RouteDetailsPageState createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  late GoogleMapController mapController;
  late LatLng initialPosition;

  @override
  void initState() {
    super.initState();
    // تعيين الموقع الافتراضي إذا كانت البيانات غير متوفرة
    initialPosition = widget.routeData['startLocation'] != null
        ? LatLng(widget.routeData['startLocation'].latitude,
            widget.routeData['startLocation'].longitude)
        : const LatLng(30.033333, 31.233334); // موقع افتراضي (القاهرة, مصر)
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل الطريق"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 14.0,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("تفاصيل الطريق هنا"),
          ),
        ],
      ),
    );
  }
}
