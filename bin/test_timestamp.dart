import 'package:fusionneur/services/paths/export_path_builder.dart';

void main() {
  final now = DateTime(2025, 8, 28, 16, 35, 7); // 28 août 2025 à 16:35:07
  print("Now     : ${timestampForFs(now)}");

  final midnight = DateTime(2025, 1, 1, 0, 0, 0);
  print("Midnight: ${timestampForFs(midnight)}");

  final singleDigit = DateTime(2025, 3, 5, 4, 7, 9); // mois/jour/heure/min/sec à 1 chiffre
  print("Single  : ${timestampForFs(singleDigit)}");

  // Et pourquoi pas la date actuelle
  print("Current : ${timestampForFs(DateTime.now())}");
}
