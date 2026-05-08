import 'package:flutter/material.dart';

class VehicleImageHelper {
  static const Map<String, String> _vehicleImages = {
    // Toyota
    'toyota_corolla': 'images/vehicles/toyota_corolla.jpg',
    'toyota_camry': 'images/vehicles/toyota_camry.jpg', 
    'toyota_rav4': 'images/vehicles/toyota_rav4.jpg',
    'toyota_aqua': 'images/vehicles/toyota_aqua.jpg',
    'toyota_prius': 'images/vehicles/toyota_prius.jpg',
    'toyota_fortuner': 'images/vehicles/toyota_fortuner.jpg',
    // Nissan
    'nissan_sunny': 'images/vehicles/nissan_sunny.jpg',
    'nissan_x-trail': 'images/vehicles/nissan_x-trail.jpg',
    'nissan_gt-r': 'images/vehicles/nissan_gtr.jpg',
    'nissan_patrol': 'images/vehicles/nissan_patrol.jpg',
    // Honda
    'honda_civic': 'images/vehicles/honda_civic.jpg',
    'honda_vezel': 'images/vehicles/honda_vezel.jpg',
    // Suzuki
    'suzuki_alto': 'images/vehicles/suzuki_alto.jpg',
    'suzuki_wagon r': 'images/vehicles/suzuki_wagonr.jpg',
    'suzuki_vitara': 'images/vehicles/suzuki_vitara.jpg',
    'suzuki_estilo': 'images/vehicles/suzuki_estilo.jpg',
    // Mazda
    'mazda_cx-5': 'images/vehicles/mazda_cx-5.jpg',
    'mazda_mazda6': 'images/vehicles/mazda6.jpg',
    'mazda_rx-8': 'images/vehicles/mazda_rx8.jpg',
    // BMW
    'bmw_x1': 'images/vehicles/bmw_x1.jpg',
    'bmw_x5': 'images/vehicles/bmw_x5.jpg',
    'bmw_740i': 'images/vehicles/bmw_740i.jpg',
    'bmw_Z4': 'images/vehicles/bmw_z4.jpg',
    // Kia
    'kia_picanto': 'images/vehicles/kia_picanto.jpg',
    'kia_sportage': 'images/vehicles/kia_sportage.jpg',
    'kia_carnival': 'images/vehicles/kia_carnival.jpg',
    // Hyundai
    'hyundai_i10': 'images/vehicles/hyundai_i10.jpg',
    'hyundai_santa fe': 'images/vehicles/hyundai_santafe.jpg',
  };

  /// Returns local asset path for brand+model, or null if not found
  static String? getImage(String? brand, String? model) {
    if (brand == null || model == null) return null;
    final key = '${brand.toLowerCase()}_${model.toLowerCase()}';
    return _vehicleImages[key];
  }

  /// Returns an ImageProvider — model image if found, else fallback
  static ImageProvider getImageProvider(String? brand, String? model) {
    final path = getImage(brand, model);
    if (path != null) return AssetImage(path);
    return const AssetImage('images/dashcar.png');
  }

  /// Returns a properly fitted Image widget that won't crop
  static Widget buildFittedImage({
    String? brand,
    String? model,
    String? photoUrl,
    double size = 50,
    Color backgroundColor = Colors.white,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          photoUrl != null
              ? Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _fallbackImage(brand, model),
              )
              : _fallbackAsset(brand, model),
    );
  }

  static Widget _fallbackAsset(String? brand, String? model) {
    final path = getImage(brand, model) ?? 'images/dashcar.png';
    return Image.asset(path, fit: BoxFit.contain);
  }

  static Widget _fallbackImage(String? brand, String? model) {
    return _fallbackAsset(brand, model);
  }
}
