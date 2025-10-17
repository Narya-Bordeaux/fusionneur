import 'package:hive/hive.dart';
part 'hive_file_ordering_policy.g.dart';

@HiveType(typeId: 11)
class HiveFileOrderingPolicy extends HiveObject {
  @HiveField(0) final List<String>? explicitOrder;
  @HiveField(1) final bool fallbackTree;

  HiveFileOrderingPolicy({this.explicitOrder, this.fallbackTree = true});
}
