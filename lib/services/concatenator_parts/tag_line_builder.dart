// Service qui construit la ligne de tags sous chaque bannière de fichier.

import 'package:fusionneur/core/constants.dart';

class TagLineBuilder {
  const TagLineBuilder();

  /// Construit la ligne de tags pour un fichier donné.
  /// Inclut : ::FUSION::code:<fileName>, ::FUSION::code:<N,>
  String build({
    required String fileName,
    required int fileNumber,
  }) {
    return '${FusionTags.byName(FusionTags.code, fileName)} '
        '${FusionTags.byNumber(FusionTags.code, fileNumber)} ';
  }
}
