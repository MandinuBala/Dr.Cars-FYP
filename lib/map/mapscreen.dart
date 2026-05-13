import 'dart:async';
import 'dart:convert';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_cars_fyp/widgets/app_bottom_nav.dart';

const String _googleApiKey = 'AIzaSyDWVyDHQmAKS3Q4dvsl1qtrzjvmFbnSNaM';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Position? _userPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _distanceText = '';
  String _durationText = '';
  bool _isLoading = true;
  bool _isSearching = false;
  Map<String, dynamic>? _selectedPlace;
  bool _showReviews = false;
  List _reviews = [];
  bool _isCardCollapsed = false;
  List<dynamic> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() => _userPosition = position);
    await _searchNearbyPlaces();
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        13,
      ),
    );
  }

  Future<void> _searchNearbyPlaces() async {
    if (_userPosition == null) return;
    setState(() => _isLoading = true);

    final lat = _userPosition!.latitude;
    final lng = _userPosition!.longitude;
    final Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'You are here'),
      ),
    );

    final searchTypes = {
      'car_repair': BitmapDescriptor.hueRed,
      'car_dealer': BitmapDescriptor.hueOrange,
    };

    for (final entry in searchTypes.entries) {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng&radius=5000&type=${entry.key}&key=$_googleApiKey',
      );
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        for (final place in data['results']) {
          final placeId = place['place_id'];
          final placeLat = place['geometry']['location']['lat'];
          final placeLng = place['geometry']['location']['lng'];

          markers.add(
            Marker(
              markerId: MarkerId(placeId),
              position: LatLng(placeLat, placeLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(entry.value),
              infoWindow: InfoWindow(
                title: place['name'],
                snippet: '⭐ ${place['rating'] ?? 'N/A'}',
              ),
              onTap: () => _onMarkerTapped(place),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
  }

  Future<void> _searchNearbyByType(String type, String label) async {
    if (_userPosition == null) return;

    setState(() {
      _isLoading = true;
      _selectedPlace = null;
      _showReviews = false;
      _showSuggestions = false;
      _searchController.text = label;
    });

    final lat = _userPosition!.latitude;
    final lng = _userPosition!.longitude;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng&radius=5000&type=$type&key=$_googleApiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    final Set<Marker> markers = Set.from(
      _markers.where((m) => m.markerId.value == 'user'),
    );

    final hue = {
          'car_repair': BitmapDescriptor.hueRed,
          'car_dealer': BitmapDescriptor.hueOrange,
          'gas_station': BitmapDescriptor.hueGreen,
          'electric_vehicle_charging_station': BitmapDescriptor.hueBlue,
        }[type] ??
        BitmapDescriptor.hueViolet;

    if (data['status'] == 'OK') {
      for (final place in data['results']) {
        final placeLat = place['geometry']['location']['lat'];
        final placeLng = place['geometry']['location']['lng'];

        markers.add(
          Marker(
            markerId: MarkerId(place['place_id']),
            position: LatLng(placeLat, placeLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: '⭐ ${place['rating'] ?? 'N/A'}',
            ),
            onTap: () => _onMarkerTapped(place),
          ),
        );
      }

      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 13),
      );
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
  }

  Timer? _debounce;
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      if (query.length > 2) {
        _fetchAutocompleteSuggestions(query);
      } else {
        setState(() {
          _searchSuggestions = [];
          _showSuggestions = false;
        });
      }
    });
  }

  Future<void> _fetchAutocompleteSuggestions(String query) async {
    if (_userPosition == null) return;
    setState(() => _isSearching = true);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&location=${_userPosition!.latitude},${_userPosition!.longitude}'
      '&radius=50000&key=$_googleApiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    setState(() {
      _isSearching = false;
      if (data['status'] == 'OK') {
        _searchSuggestions = data['predictions'];
        _showSuggestions = true;
      }
    });
  }

  Future<void> _selectSuggestion(dynamic suggestion) async {
    final placeId = suggestion['place_id'];
    _searchController.text = suggestion['description'];
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=geometry,name,rating,user_ratings_total,vicinity,'
      'opening_hours,photos,formatted_phone_number,reviews,website'
      '&key=$_googleApiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final result = data['result'];
      final lat = result['geometry']['location']['lat'];
      final lng = result['geometry']['location']['lng'];

      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
      );

      final Set<Marker> updatedMarkers = Set.from(_markers);
      updatedMarkers.add(
        Marker(
          markerId: const MarkerId('searched'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(title: result['name'] ?? ''),
          onTap: () => _showPlaceCard(result, placeId),
        ),
      );
      setState(() => _markers = updatedMarkers);
      _showPlaceCard(result, placeId);
    }
  }

  void _showPlaceCard(Map<String, dynamic> result, String placeId) {
    final photos = result['photos'] as List?;
    setState(() {
      _selectedPlace = {
        'place_id': placeId,
        'name': result['name'] ?? '',
        'rating': result['rating']?.toString() ?? 'N/A',
        'total_ratings':
            result['user_ratings_total']?.toString() ?? '0',
        'open_now': result['opening_hours']?['open_now'],
        'lat': result['geometry']['location']['lat'],
        'lng': result['geometry']['location']['lng'],
        'photo_ref': photos != null && photos.isNotEmpty
            ? photos[0]['photo_reference']
            : null,
        'address':
            result['vicinity'] ?? result['formatted_address'] ?? '',
        'phone': result['formatted_phone_number'] ?? '',
        'hours': result['opening_hours']?['weekday_text'] ?? [],
        'website': result['website'] ?? '',
      };
      _reviews = result['reviews'] ?? [];
      _showReviews = false;
      _isCardCollapsed = false;
    });
  }

  Future<void> _onMarkerTapped(Map<String, dynamic> place) async {
    setState(() {
      _selectedPlace = {
        'place_id': place['place_id'],
        'name': place['name'],
        'rating': place['rating']?.toString() ?? 'N/A',
        'total_ratings':
            place['user_ratings_total']?.toString() ?? '0',
        'open_now': place['opening_hours']?['open_now'],
        'lat': place['geometry']['location']['lat'],
        'lng': place['geometry']['location']['lng'],
        'photo_ref': place['photos']?[0]?['photo_reference'],
        'address': place['vicinity'] ?? '',
        'phone': '',
        'hours': [],
      };
      _showReviews = false;
      _isCardCollapsed = false;
      _reviews = [];
    });

    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_selectedPlace!['lat'], _selectedPlace!['lng']),
        15,
      ),
    );

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${place['place_id']}'
      '&fields=formatted_phone_number,opening_hours,reviews,website'
      '&key=$_googleApiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final result = data['result'];
      setState(() {
        _selectedPlace!['phone'] =
            result['formatted_phone_number'] ?? '';
        _selectedPlace!['hours'] =
            result['opening_hours']?['weekday_text'] ?? [];
        _reviews = result['reviews'] ?? [];
        _selectedPlace!['website'] = result['website'] ?? '';
      });
    }
  }

  Future<void> _getRoute(double destLat, double destLng) async {
    if (_userPosition == null) return;
    setState(() => _isLoading = true);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${_userPosition!.latitude},${_userPosition!.longitude}'
      '&destination=$destLat,$destLng&mode=driving&key=$_googleApiKey',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);
    setState(() => _isLoading = false);

    if (data['status'] == 'OK') {
      final points =
          data['routes'][0]['overview_polyline']['points'];
      final distance =
          data['routes'][0]['legs'][0]['distance']['text'];
      final duration =
          data['routes'][0]['legs'][0]['duration']['text'];
      final decoded = _decodePolyline(points);

      setState(() {
        _distanceText = distance;
        _durationText = duration;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: decoded,
            color: AppColors.gold,
            width: 4,
          ),
        };
        _isCardCollapsed = true;
      });

      double minLat = decoded.first.latitude,
          maxLat = decoded.first.latitude;
      double minLng = decoded.first.longitude,
          maxLng = decoded.first.longitude;
      for (var p in decoded) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          80,
        ),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openWebsite(String url) async {
    final uri =
        Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: _userPosition == null
              ? Scaffold(
                  backgroundColor: AppColors.richBlack,
                  body: const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.gold),
                  ),
                )
              : Stack(
                  children: [
                    // ── Google Map ──────────────────────────────────
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                        ),
                        zoom: 13,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapType: MapType.normal,
                      onMapCreated: (c) => _mapController.complete(c),
                      onTap: (_) {
                        setState(() {
                          _selectedPlace = null;
                          _showReviews = false;
                          _showSuggestions = false;
                        });
                        _searchFocus.unfocus();
                      },
                    ),

                    // ── Loading ─────────────────────────────────────
                    if (_isLoading)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.gold),
                        ),
                      ),

                    // ── Search bar ──────────────────────────────────
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 12,
                      right: 12,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.borderGold),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: AppColors.gold,
                                  ),
                                  onPressed: () =>
                                      Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DashboardScreen(),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocus,
                                    style: GoogleFonts.jost(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: AppStrings.get(
                                          'search_hint', lang),
                                      hintStyle: GoogleFonts.jost(
                                        fontSize: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14),
                                    ),
                                    onSubmitted: (val) {
                                      if (val.isNotEmpty) {
                                        _fetchAutocompleteSuggestions(
                                            val);
                                      }
                                    },
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _showSuggestions = false;
                                        _searchSuggestions = [];
                                      });
                                    },
                                  )
                                else
                                  _isSearching
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                        )
                                      : const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Icon(
                                            Icons.search,
                                            color: AppColors.gold,
                                          ),
                                        ),
                              ],
                            ),
                          ),

                          // ── Autocomplete suggestions ──────────────
                          if (_showSuggestions &&
                              _searchSuggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.borderGold),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount:
                                    _searchSuggestions.length > 5
                                        ? 5
                                        : _searchSuggestions.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(
                                  height: 1,
                                  color: AppColors.borderGold,
                                  indent: 16,
                                ),
                                itemBuilder: (_, i) {
                                  final s = _searchSuggestions[i];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.location_on,
                                      color: AppColors.gold,
                                      size: 20,
                                    ),
                                    title: Text(
                                      s['structured_formatting']
                                              ?['main_text'] ??
                                          s['description'],
                                      style: GoogleFonts.jost(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      s['structured_formatting']
                                              ?['secondary_text'] ??
                                          '',
                                      style: GoogleFonts.jost(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    dense: true,
                                    onTap: () =>
                                        _selectSuggestion(s),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Filter chips ────────────────────────────────
                    if (!_showSuggestions)
                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top + 76,
                        left: 12,
                        right: 12,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip(
                                AppStrings.get('garages', lang),
                                AppColors.error,
                                () => _searchNearbyByType(
                                    'car_repair', 'Garages'),
                              ),
                              const SizedBox(width: 8),
                              _filterChip(
                                AppStrings.get(
                                    'service_centers', lang),
                                Colors.orange,
                                () => _searchNearbyByType(
                                    'car_dealer', 'Service Centers'),
                              ),
                              const SizedBox(width: 8),
                              _filterChip(
                                AppStrings.get('fuel_stations', lang),
                                AppColors.success,
                                () => _searchNearbyByType(
                                    'gas_station', 'Fuel Stations'),
                              ),
                              const SizedBox(width: 8),
                              _filterChip(
                                AppStrings.get('ev_charging', lang),
                                Colors.blue,
                                () => _searchNearbyByType(
                                    'electric_vehicle_charging_station',
                                    'EV Charging'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Distance badge ──────────────────────────────
                    if (_distanceText.isNotEmpty)
                      Positioned(
                        bottom:
                            _selectedPlace != null ? 320 : 100,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.borderGold),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.directions_car,
                                color: AppColors.gold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_distanceText  ·  $_durationText',
                                style: GoogleFonts.jost(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _polylines.clear();
                                  _distanceText = '';
                                  _durationText = '';
                                }),
                                child: const Icon(
                                  Icons.close,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Legend ──────────────────────────────────────
                    if (!_showSuggestions)
                      Positioned(
                        bottom: _selectedPlace != null ? 320 : 16,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.borderGold),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _legendItem(
                                  Icons.location_on,
                                  'Garage',
                                  AppColors.error),
                              const SizedBox(height: 4),
                              _legendItem(
                                  Icons.location_on,
                                  'Service Center',
                                  Colors.orange),
                              const SizedBox(height: 4),
                              _legendItem(
                                  Icons.location_on,
                                  'Searched',
                                  Colors.cyan),
                            ],
                          ),
                        ),
                      ),

                    // ── Map controls ────────────────────────────────
                    Positioned(
                      right: 12,
                      bottom: _selectedPlace != null ? 320 : 80,
                      child: Column(
                        children: [
                          _mapBtn(Icons.add, () async {
                            (await _mapController.future)
                                .animateCamera(CameraUpdate.zoomIn());
                          }),
                          const SizedBox(height: 8),
                          _mapBtn(Icons.remove, () async {
                            (await _mapController.future).animateCamera(
                                CameraUpdate.zoomOut());
                          }),
                          const SizedBox(height: 8),
                          _mapBtn(Icons.refresh, () {
                            setState(() {
                              _polylines.clear();
                              _distanceText = '';
                              _durationText = '';
                              _selectedPlace = null;
                              _showReviews = false;
                              _isCardCollapsed = false;
                              _searchController.clear();
                              _showSuggestions = false;
                            });
                            _searchNearbyPlaces();
                          }),
                          const SizedBox(height: 8),
                          _mapBtn(Icons.my_location, () async {
                            if (_userPosition != null) {
                              (await _mapController.future)
                                  .animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(
                                    _userPosition!.latitude,
                                    _userPosition!.longitude,
                                  ),
                                  14,
                                ),
                              );
                            }
                          }),
                        ],
                      ),
                    ),

                    // ── Place detail card ───────────────────────────
                    if (_selectedPlace != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              constraints: BoxConstraints(
                                maxHeight: _isCardCollapsed
                                    ? 130
                                    : MediaQuery.of(context)
                                            .size
                                            .height *
                                        0.52,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                border: const Border(
                                  top: BorderSide(
                                      color: AppColors.borderGold),
                                  left: BorderSide(
                                      color: AppColors.borderGold),
                                  right: BorderSide(
                                      color: AppColors.borderGold),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold
                                        .withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 12, 20, 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Drag handle
                                    Center(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _isCardCollapsed =
                                              !_isCardCollapsed,
                                        ),
                                        child: Container(
                                          width: 40,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: AppColors.textMuted,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Photo
                                    if (_selectedPlace![
                                            'photo_ref'] !=
                                        null)
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Image.network(
                                          'https://maps.googleapis.com/maps/api/place/photo'
                                          '?maxwidth=600&photo_reference=${_selectedPlace!['photo_ref']}'
                                          '&key=$_googleApiKey',
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  const SizedBox(),
                                        ),
                                      ),
                                    const SizedBox(height: 10),

                                    // Name
                                    Text(
                                      _selectedPlace!['name'],
                                      style: GoogleFonts
                                          .cormorantGaramond(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Rating & Status
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: AppColors.gold,
                                            size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_selectedPlace!['rating']}  ·  ${_selectedPlace!['total_ratings']} ${AppStrings.get('reviews', lang)}',
                                          style: GoogleFonts.jost(
                                            fontSize: 13,
                                            color:
                                                AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _selectedPlace![
                                                        'open_now'] ==
                                                    true
                                                ? AppColors.success
                                                    .withOpacity(0.1)
                                                : AppColors.error
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    6),
                                            border: Border.all(
                                              color: _selectedPlace![
                                                          'open_now'] ==
                                                      true
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                          ),
                                          child: Text(
                                            _selectedPlace![
                                                        'open_now'] ==
                                                    true
                                                ? AppStrings.get(
                                                    'open', lang)
                                                : AppStrings.get(
                                                    'closed', lang),
                                            style: GoogleFonts.jost(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: _selectedPlace![
                                                          'open_now'] ==
                                                      true
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Address
                                    if ((_selectedPlace!['address'] ??
                                            '')
                                        .isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.location_on,
                                              size: 13,
                                              color: AppColors.gold),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _selectedPlace![
                                                  'address'],
                                              style: GoogleFonts.jost(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 14),

                                    // Action buttons
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _actionBtn(
                                            Icons.directions,
                                            AppStrings.get(
                                                'directions', lang),
                                            AppColors.gold,
                                            () => _getRoute(
                                              _selectedPlace!['lat'],
                                              _selectedPlace!['lng'],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _actionBtn(
                                            Icons.open_in_new,
                                            AppStrings.get(
                                                'open_maps', lang),
                                            Colors.blue,
                                            () => _openInGoogleMaps(
                                              _selectedPlace!['lat'],
                                              _selectedPlace!['lng'],
                                            ),
                                          ),
                                          if ((_selectedPlace![
                                                      'phone'] ??
                                                  '')
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            _actionBtn(
                                              Icons.phone,
                                              AppStrings.get(
                                                  'call', lang),
                                              AppColors.success,
                                              () => _makePhoneCall(
                                                  _selectedPlace![
                                                      'phone']),
                                            ),
                                          ],
                                          if ((_selectedPlace![
                                                      'website'] ??
                                                  '')
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            _actionBtn(
                                              Icons.language,
                                              AppStrings.get(
                                                  'website', lang),
                                              Colors.indigo,
                                              () => _openWebsite(
                                                  _selectedPlace![
                                                      'website']),
                                            ),
                                          ],
                                          const SizedBox(width: 8),
                                          _actionBtn(
                                            Icons.share,
                                            AppStrings.get(
                                                'share', lang),
                                            Colors.orange,
                                            () => Share.share(
                                              '${_selectedPlace!['name']}\n${_selectedPlace!['address']}\n'
                                              'https://www.google.com/maps/search/?api=1'
                                              '&query=${_selectedPlace!['lat']},${_selectedPlace!['lng']}',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _actionBtn(
                                            _showReviews
                                                ? Icons.expand_less
                                                : Icons.reviews,
                                            AppStrings.get(
                                                'reviews', lang),
                                            Colors.purple,
                                            () => setState(() =>
                                                _showReviews =
                                                    !_showReviews),
                                          ),
                                          const SizedBox(width: 8),
                                          _actionBtn(
                                            Icons.close,
                                            AppStrings.get(
                                                'close', lang),
                                            AppColors.textMuted,
                                            () => setState(() {
                                              _selectedPlace = null;
                                              _showReviews = false;
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Opening hours
                                    if ((_selectedPlace!['hours']
                                            as List)
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Text(
                                        AppStrings.get(
                                            'opening_hours', lang),
                                        style: GoogleFonts.jost(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.gold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...(_selectedPlace!['hours']
                                              as List)
                                          .map(
                                            (h) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2),
                                              child: Text(
                                                h.toString(),
                                                style: GoogleFonts.jost(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ],
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),

                            // ── Reviews panel ─────────────────────
                            if (_showReviews)
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context)
                                              .size
                                              .height *
                                          0.32,
                                ),
                                color: AppColors.surfaceDark,
                                child: _reviews.isNotEmpty
                                    ? ListView.builder(
                                        padding:
                                            const EdgeInsets.fromLTRB(
                                                16, 8, 16, 16),
                                        itemCount: _reviews.length,
                                        itemBuilder: (_, i) =>
                                            _reviewCard(_reviews[i]),
                                      )
                                    : Center(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.all(16),
                                          child: Text(
                                            AppStrings.get(
                                                'no_reviews', lang),
                                            style: GoogleFonts.jost(
                                              color:
                                                  AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
          bottomNavigationBar: AppBottomNav(currentIndex: 1),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _filterChip(
      String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderGold),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.jost(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _mapBtn(IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderGold),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.gold),
        ),
      );

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.jost(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _legendItem(IconData icon, String label, Color color) =>
      Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.jost(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );

  Widget _reviewCard(dynamic review) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.borderGold),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surfaceDark,
              backgroundImage: review['profile_photo_url'] != null
                  ? NetworkImage(review['profile_photo_url'])
                  : null,
              child: review['profile_photo_url'] == null
                  ? Text(
                      (review['author_name'] ?? 'A')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                      style: GoogleFonts.jost(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                review['author_name'] ?? '',
                style: GoogleFonts.jost(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 12,
                  color: i < (review['rating'] ?? 0)
                      ? AppColors.gold
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          review['text'] ?? '',
          style: GoogleFonts.jost(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          review['relative_time_description'] ?? '',
          style: GoogleFonts.jost(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}