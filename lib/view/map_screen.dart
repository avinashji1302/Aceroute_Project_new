import 'package:ace_routes/controller/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng _startLocation = LatLng(41.500000, -100.000000);
  LatLng? _currentLocation;

  Set<Marker> markers = {};
  final locationMapController = Get.put(MapControllers());

  @override
  void initState() {
    super.initState();
    fetchOrderData();
  }

  Future<void> fetchOrderData() async {
    await locationMapController.FetchAllOrderLocation();
    AllOrders();
  }

  void AllOrders() {
    for (var data in locationMapController.orders) {
      String location = data.geo;
      String address = data.address;
      String customerName = data.cnm;

      final locationParts = location.split(',');
      double? latitude = double.tryParse(locationParts[0]);
      double? longitude = double.tryParse(locationParts[1]);

      if (latitude != null && longitude != null) {
        LatLng latLng = LatLng(latitude, longitude);

        // Assign current location only once — from the first valid order
        _currentLocation ??= latLng;

        markers.add(
          Marker(
            markerId: MarkerId('marker_$customerName'),
            position: latLng,
            infoWindow: InfoWindow(
              title: customerName,
              snippet: address,
            ),
          ),
        );
      }
    }

    // Move camera to first marker location
    if (_currentLocation != null && mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }

    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    // Move camera if location already set
    if (_currentLocation != null) {
      controller.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (locationMapController.orderLocations.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        return GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? _startLocation,
            zoom: 12.0,
          ),
          markers: markers,
        );
      }),
    );
  }
}
