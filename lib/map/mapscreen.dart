import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:dr_cars_fyp/admin/ratings/rating.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

int _selectedIndex = 1;

class _MapScreenState extends State<MapScreen> {
  final AuthService _authService = AuthService();
  LocationData? _userLocation;
  final Location _location = Location();
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedCenter;
  bool _showReviews = false;
  List<LatLng> _polylineCoordinates = [];
  String _distanceText = "";
  bool _isCardCollapsed = false;

  Future<void> _getRoute(LatLng destination) async {
    final originLat = _userLocation!.latitude!;
    final originLng = _userLocation!.longitude!;
    final apiKey = "AIzaSyCAkq8qyW7RiNAqcy7ZJ3E-nrtuHfoaIs4";

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final points = data['routes'][0]['overview_polyline']['points'];
      final polylinePoints = PolylinePoints().decodePolyline(points);

      final distance = data['routes'][0]['legs'][0]['distance']['text'];

      final decodedCoordinates =
          polylinePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

      setState(() {
        _polylineCoordinates = decodedCoordinates;
        _distanceText = distance;
      });

      // Fit the map to the route bounds
      if (_polylineCoordinates.isNotEmpty) {
        final bounds = LatLngBounds(
          _polylineCoordinates.first,
          _polylineCoordinates.first,
        );

        for (var latLng in _polylineCoordinates) {
          bounds.extend(latLng);
        }

        _mapController.fitBounds(
          bounds,
          options: FitBoundsOptions(padding: EdgeInsets.all(50)),
        );
      }
    } else {
      print("Directions API error: ${data['status']}");
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  final List<Map<String, dynamic>> serviceCenters = [
    {
      "name": "Dr Cars Colombo Service Center",
      "lat": 6.9271,
      "lng": 79.8612,
      "description":
          "Located in the heart of Colombo, providing 24/7 customer support.",
      "image": "images/colombo.jpg",
      "phone": "0762611651",
    },
    {
      "name": "Dr Cars Kandy Service Center",
      "lat": 7.2906,
      "lng": 80.6337,
      "description":
          "Situated near the Kandy Lake, offering maintenance services.",
      "image": "images/kandy.jpg",
      "phone": "0762611651",
    },
    {
      "name": "Dr Cars Galle Service Center",
      "lat": 6.0535,
      "lng": 80.2210,
      "description":
          "A modern facility near Galle Fort, specializing in quick repairs.",
      "image": "images/galle.jpg",
      "phone": "0762611651",
    },
    {
      "name": "Dr Cars Jaffna Service Center",
      "lat": 9.6615,
      "lng": 80.0255,
      "description":
          "Serving the northern region with dedicated support services.",
      "image": "images/jaffna.jpg",
      "phone": "0762611651",
    },
    {
      "name": "Dr Cars Anuradhapura Service Center",
      "lat": 8.3114,
      "lng": 80.4037,
      "description":
          "Located close to heritage sites, ensuring reliable service.",
      "image": "images/anuradapura.jpg",
      "phone": "0762611651",
    },
    {
      "name": "Dr Cars Ampara Service Center",
      "lat": 7.301763770344583,
      "lng": 81.67479843992851,
      "description":
          "Located close to heritage sites, ensuring reliable service.",
      "image": "images/ampara.jpg",
      "phone": "0762611651",
    },
  ];

  final List<Map<String, dynamic>> fuelCenters = [
    {
      "fid": "f1",
      "fname": "LankaFuel Maharagama",
      "flat": 6.8510,
      "flng": 79.9221,
      "fdescription": "Fuel station near Maharagama Town",
      "fphone": "0771234567",
    },
    {
      "fid": "f2",
      "fname": "LankaFuel Kurunegala",
      "flat": 7.4863,
      "flng": 80.3621,
      "fdescription": "24-hour fuel station in Kurunegala town.",
      "fphone": "0772345678",
    },
    {
      "fid": "f3",
      "fname": "LankaFuel Badulla",
      "flat": 6.9934,
      "flng": 81.0550,
      "fdescription": "Badulla main road station, diesel and petrol available.",
      "fphone": "0773456789",
    },
    {
      "fid": "f4",
      "fname": "LankaFuel Matara",
      "flat": 5.9485,
      "flng": 80.5353,
      "fdescription": "Matara beach-side station with 24/7 service.",
      "fphone": "0774567890",
    },
    {
      "fid": "f5",
      "fname": "LankaFuel Trincomalee",
      "flat": 8.5880,
      "flng": 81.2152,
      "fdescription": "Located near the Trinco clock tower.",
      "fphone": "0775678901",
    },
    {
      "fid": "f6",
      "fname": "LankaFuel Ratnapura",
      "flat": 6.6828,
      "flng": 80.3996,
      "fdescription": "Gem city main fuel center on Pelmadulla road.",
      "fphone": "0776789012",
    },
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _trackUserLocation();
  }

  // fuel centers card
  void _showFuelBottomSheet(
    BuildContext context,
    String fname,
    String fdescription,
    String fphone,
    double flat,
    double flng,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  fname,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(fdescription, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCardButton(
                      Icons.arrow_back,
                      "Back",
                      Colors.red,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildCardButton(
                      Icons.phone,
                      "Call",
                      Colors.green,
                      onPressed: () {
                        if (_selectedCenter!['fphone'] != null) {
                          _makePhoneCall(_selectedCenter!['fphone']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("No phone number available."),
                            ),
                          );
                        }
                      },
                    ),
                    _buildCardButton(
                      Icons.directions,
                      "Directions",
                      Colors.blue,
                      onPressed: () {
                        final LatLng centerLocation = LatLng(flat, flng);
                        _getRoute(centerLocation);
                        setState(() {
                          _isCardCollapsed = !_isCardCollapsed;
                        });
                      },
                    ),
                    _buildCardButton(
                      Icons.share,
                      "Share",
                      Colors.orange,
                      onPressed: () {
                        final shareText =
                            'Check out this fuel center:\n'
                            '$fname\n$fdescription\n'
                            'Location: https://www.google.com/maps/search/?api=1&query=$flat,$flng';
                        Share.share(shareText);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _location.changeSettings(accuracy: LocationAccuracy.high, interval: 3000);

    final LocationData locationData = await _location.getLocation();
    setState(() {
      _userLocation = locationData;
    });
  }

  void _trackUserLocation() {
    _location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _userLocation = currentLocation;
      });
    });
  }

  double _calculateAverageRating(List<Map<String, dynamic>> feedbacks) {
    if (feedbacks.isEmpty) return 0.0;
    int totalRating = 0;

    for (var feedback in feedbacks) {
      totalRating += int.tryParse(feedback['rating']?.toString() ?? '0') ?? 0;
    }

    return totalRating / feedbacks.length;
  }

  Future<List<Map<String, dynamic>>> _fetchFeedbacks() async {
    if (_selectedCenter == null) {
      return [];
    }

    final response = await http.get(
      Uri.parse(
        '${_authService.baseUrl}/feedbacks?serviceCenterId=${Uri.encodeComponent(_selectedCenter!['name'].toString())}',
      ),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Widget _buildCardButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchFeedbacks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final feedbacks = snapshot.data ?? [];
        if (feedbacks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "No reviews available for this center yet. Be the first to add a review!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
          );
        }

        final averageRating = _calculateAverageRating(feedbacks);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Reviews (${feedbacks.length})",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color:
                                index < averageRating.floor()
                                    ? Colors.orange
                                    : Colors.grey[300],
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 20),
                itemCount: feedbacks.length,
                itemBuilder: (context, index) {
                  final feedback = feedbacks[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                feedback['name'] ?? 'Anonymous',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatDate(feedback['date'] ?? ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                Icons.star,
                                size: 18,
                                color:
                                    index <
                                            (int.tryParse(
                                                  feedback['rating']
                                                          ?.toString() ??
                                                      '0',
                                                ) ??
                                                0)
                                        ? Colors.orange
                                        : Colors.grey[300],
                              );
                            }),
                          ),
                          SizedBox(height: 12),
                          Text(
                            feedback['feedback'] ?? '',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        ),
        title: const Text(
          " Dr Cars Service Centers",
          style: TextStyle(fontSize: 25),
        ),
      ),
      body:
          _userLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(
                        _userLocation!.latitude!,
                        _userLocation!.longitude!,
                      ),
                      zoom: 9.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      interactiveFlags: InteractiveFlag.all,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.dr_cars',
                      ),
                      if (_distanceText.isNotEmpty)
                        Positioned(
                          top: 100, // adjust vertically
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Distance: $_distanceText",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _polylineCoordinates,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),

                      MarkerLayer(
                        markers: [
                          //  User location
                          Marker(
                            point: LatLng(
                              _userLocation!.latitude!,
                              _userLocation!.longitude!,
                            ),
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 50,
                            ),
                          ),

                          // Service centers
                          for (var center in serviceCenters)
                            Marker(
                              point: LatLng(center["lat"], center["lng"]),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCenter = center;
                                    _showReviews = false;
                                    _isCardCollapsed = false;
                                  });
                                },
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ),

                          // Fuel centers
                          for (var fcenter in fuelCenters)
                            Marker(
                              point: LatLng(fcenter["flat"], fcenter["flng"]),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () {
                                  _showFuelBottomSheet(
                                    context,
                                    fcenter["fname"],
                                    fcenter["fdescription"],
                                    fcenter["fphone"],
                                    fcenter["flat"],
                                    fcenter["flng"],
                                  );
                                },
                                child: const Icon(
                                  Icons.local_gas_station,
                                  color: Color.fromARGB(255, 1, 11, 2),
                                  size: 40,
                                ),
                              ),
                            ),
                        ],
                      ),

                      Positioned(
                        top: 20,
                        right: 10,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.refresh, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              _polylineCoordinates.clear();
                              _isCardCollapsed = false;
                              _showReviews = false;
                              _distanceText = "";
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Zoom controls
                  Positioned(
                    top: 20,
                    right: 10,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          heroTag: "zoom_in",
                          mini: true,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.zoom_in, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              _mapController.move(
                                _mapController.center,
                                _mapController.zoom + 1,
                              );
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        FloatingActionButton(
                          heroTag: "zoom_out",
                          mini: true,
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.zoom_out,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _mapController.move(
                                _mapController.center,
                                _mapController.zoom - 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom card when a center is selected
                  if (_selectedCenter != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Service Center Info Card
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: _isCardCollapsed ? 150 : null,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  _showReviews
                                      ? BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                      )
                                      : BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Drag indicator
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),

                                  // Title & location
                                  Text(
                                    _selectedCenter!['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "(${_selectedCenter!['lat']}, ${_selectedCenter!['lng']})",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),

                                  // Description
                                  Text(
                                    _selectedCenter!['description'],
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 12),

                                  // Buttons Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildCardButton(
                                        Icons.arrow_back,
                                        "Back",
                                        Colors.red,
                                        onPressed: () {
                                          setState(() {
                                            _selectedCenter = null;
                                            _isCardCollapsed =
                                                false; // reset on back
                                          });
                                        },
                                      ),
                                      _buildCardButton(
                                        Icons.phone,
                                        "Call",
                                        Colors.green,
                                        onPressed: () {
                                          if (_selectedCenter!['phone'] !=
                                              null) {
                                            _makePhoneCall(
                                              _selectedCenter!['phone'],
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "No phone number available.",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      _buildCardButton(
                                        Icons.directions,
                                        "Directions",
                                        Colors.blue,
                                        onPressed: () {
                                          final LatLng centerLocation = LatLng(
                                            _selectedCenter!["lat"],
                                            _selectedCenter!["lng"],
                                          );
                                          _getRoute(centerLocation);

                                          setState(() {
                                            _isCardCollapsed =
                                                !_isCardCollapsed;
                                          });
                                        },
                                      ),

                                      _buildCardButton(
                                        Icons.feedback,
                                        "Feedbacks",
                                        Colors.green,
                                        onPressed: () async {
                                          setState(() {
                                            _showReviews = !_showReviews;
                                          });

                                          if (!_showReviews) {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => RatingScreen(
                                                      serviceCenterId:
                                                          _selectedCenter!['name'],
                                                    ),
                                              ),
                                            );

                                            setState(() {
                                              _showReviews = true;
                                            });
                                          }
                                        },
                                      ),
                                      _buildCardButton(
                                        Icons.share,
                                        "Share",
                                        Colors.orange,
                                        onPressed: () {
                                          final shareText =
                                              'Check out this service center:\n'
                                              '${_selectedCenter!['name']}\n${_selectedCenter!['description']}\n'
                                              'Location: https://www.google.com/maps/search/?api=1&query=${_selectedCenter!['lat']},${_selectedCenter!['lng']}';
                                          Share.share(shareText);
                                        },
                                      ),
                                    ],
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          _selectedCenter!['image'],
                                          height: 200,
                                          width: 500,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),

                          // Reviews Section
                          if (_showReviews)
                            Container(
                              height: MediaQuery.of(context).size.height * 0.4,
                              color: Colors.white,
                              child: _buildReviewsList(),
                            ),
                        ],
                      ),
                    ),
                ],
              ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location, color: Colors.white),
        onPressed: () async {
          final LocationData locationData = await _location.getLocation();
          setState(() {
            _userLocation = locationData;
          });
        },
      ),

      // Bottom nav bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OBD2Page()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServiceHistorypage()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(
            icon: Image.asset('images/logo.png', height: 30),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
