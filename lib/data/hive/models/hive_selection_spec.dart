import 'package:hive/hive.dart';
import 'package:fusionneur/services/concatenator_parts/file_selection.dart'; // pour SelectionSpec runtime

part 'hive_selection_spec.g.dart';

@HiveType(typeId: 10)
class HiveSelectionSpec extends HiveObject {
  @HiveField(0)
  final List<String> includeDirs;

  @HiveField(1)
  final List<String> excludeDirs;

  @HiveField(2)
  final List<String> includeFiles;

  @HiveField(3)
  final List<String> excludeFiles;

  HiveSelectionSpec({
    this.includeDirs = const [],
    this.excludeDirs = const [],
    this.includeFiles = const [],
    this.excludeFiles = const [],
  });

  /// Conversion vers le modèle runtime utilisé par le resolver.
  SelectionSpec toRuntime() {
    return SelectionSpec(
      includeDirs: includeDirs,
      excludeDirs: excludeDirs,
      includeFiles: includeFiles,
      excludeFiles: excludeFiles,
    );
  }
}