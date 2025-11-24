import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';

class PrayerTimeUtils {
  static Map<String, String> getPrayerTimes() {
    // ✅ Belgaum coordinates
    final coordinates = Coordinates(15.8497, 74.4977);

    // ✅ Karachi method with Hanafi madhab
    final params = CalculationMethod.karachi();
    params.madhab = Madhab.hanafi;

    // ✅ Use current date
    final date = DateTime.now();

    // ✅ Use named parameters
    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: date,
      calculationParameters: params,
    );

    final formatter = DateFormat('hh:mm a');

    return {
      'Fajr': formatter.format(prayerTimes.fajr!),
      'Sunrise': formatter.format(prayerTimes.sunrise!),
      'Dhuhr': formatter.format(prayerTimes.dhuhr!),
      'Asr': formatter.format(prayerTimes.asr!),
      'Maghrib': formatter.format(prayerTimes.maghrib!),
      'Isha': formatter.format(prayerTimes.isha!),
    };
  }
}
