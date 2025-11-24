import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class PrayerTimeModel {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTimeModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

class PrayerTimeUtils {
  static Future<PrayerTimeModel?> getPrayerTimes() async {
    Position? position = await getCurrentLocation();

    // Fallback coordinates for Surat, India if location fails
    final double lat = position?.latitude ?? 21.1702;
    final double lng = position?.longitude ?? 72.8311;

    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.karachi();
    params.madhab = Madhab.hanafi;

    final now = DateTime.now();
    final prayerTimes = PrayerTimes(
      date: now,
      coordinates: coordinates,
      calculationParameters: params,
    );

    return PrayerTimeModel(
      fajr: DateFormat('hh:mm a').format(prayerTimes.fajr!),
      sunrise: DateFormat('hh:mm a').format(prayerTimes.sunrise!),
      dhuhr: DateFormat('hh:mm a').format(prayerTimes.dhuhr!),
      asr: DateFormat('hh:mm a').format(prayerTimes.asr!),
      maghrib: DateFormat('hh:mm a').format(prayerTimes.maghrib!),
      isha: DateFormat('hh:mm a').format(prayerTimes.isha!),
    );
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Android TV or platform error fallback
      print('⚠️ Location access failed. Falling back to default: $e');
      return null;
    }
  }
}
