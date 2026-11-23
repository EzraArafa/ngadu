import 'package:geolocator/geolocator.dart';

/// Hasil penangkapan lokasi perangkat.
class GpsResult {
  const GpsResult({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

/// Service lokasi berbasis [Geolocator]. Mengelola izin lokasi dan
/// pembacaan koordinat terkini.
class LocationService {
  /// Meminta izin, lalu membaca posisi terkini.
  ///
  /// Melempar [LocationPermissionException] bila izin ditolak permanen
  /// (pengguna harus membukanya lewat pengaturan perangkat).
  static Future<GpsResult> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationPermissionException(
        'Layanan lokasi perangkat nonaktif. Nyalakan GPS lalu coba lagi.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionException(
        'Izin lokasi ditolak. Buka pengaturan aplikasi lalu aktifkan lokasi.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException(
        'Izin lokasi ditolak permanen. Aktifkan lokasi lewat pengaturan perangkat.',
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GpsResult(lat: pos.latitude, lng: pos.longitude);
  }
}

/// Error khusus izin/layanan lokasi; memisahkan kasus izin dari error umum.
class LocationPermissionException implements Exception {
  const LocationPermissionException(this.message);
  final String message;

  @override
  String toString() => message;
}
