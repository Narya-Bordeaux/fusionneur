import 'package:hive/hive.dart';
part 'hive_filter_options.g.dart';

@HiveType(typeId: 12)
class HiveFilterOptions extends HiveObject {
  @HiveField(0) final List<String> excludePatterns;
  @HiveField(1) final bool onlyDart; // <- par défaut FALSE (on accepte tout)
  HiveFilterOptions({
    this.excludePatterns = const [],
    this.onlyDart = false,
  });
}
