// test/services/storage_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusionneur/services/storage.dart';

void main() {
  group('Storage directory helpers', () {
    late Directory tmpDir;
    late Storage storage;

    setUp(() async {
      // Crée un dossier temporaire unique pour le test
      tmpDir = Directory.systemTemp.createTempSync('fusionneur_test_');
      storage = await Storage.initWithBaseDir(tmpDir.path, appName: 'fusionneur_test');
    });

    tearDown(() async {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('projectExportsDir crée le dossier exports/<slug>', () {
      final dir = storage.projectExportsDir('myProject');
      expect(dir.existsSync(), true);
      expect(dir.path.contains('exports'), true);
      expect(dir.path.contains('myproject'), true); // slug = lowercase
    });

    test('projectEntrypointExportsDir crée exports/<slug>/entrypoint', () {
      final dir = storage.projectEntrypointExportsDir('myProject');
      expect(dir.existsSync(), true);
      expect(dir.path.endsWith('entrypoint'), true);
    });

    test('projectUnusedExportsDir crée exports/<slug>/unused', () {
      final dir = storage.projectUnusedExportsDir('myProject');
      expect(dir.existsSync(), true);
      expect(dir.path.endsWith('unused'), true);
    });

    test('projectPresetsDir crée presets/<slug>', () {
      final dir = storage.projectPresetsDir('myProject');
      expect(dir.existsSync(), true);
      expect(dir.path.contains('presets'), true);
      expect(dir.path.contains('myproject'), true);
    });

    test('ensureProjectDirs crée tous les dossiers en une fois', () {
      storage.ensureProjectDirs('anotherProject');

      expect(storage.projectExportsDir('anotherProject').existsSync(), true);
      expect(storage.projectEntrypointExportsDir('anotherProject').existsSync(), true);
      expect(storage.projectUnusedExportsDir('anotherProject').existsSync(), true);
      expect(storage.projectPresetsDir('anotherProject').existsSync(), true);
    });
  });
}
