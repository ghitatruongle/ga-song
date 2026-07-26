import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB files', () {
    late Map<String, dynamic> enArb;
    late Map<String, dynamic> viArb;

    setUp(() {
      final enPath = '${Directory.current.path}/lib/l10n/app_en.arb';
      final viPath = '${Directory.current.path}/lib/l10n/app_vi.arb';

      enArb =
          json.decode(File(enPath).readAsStringSync()) as Map<String, dynamic>;
      viArb =
          json.decode(File(viPath).readAsStringSync()) as Map<String, dynamic>;
    });

    test('should be valid JSON', () {
      // setUp already parsed them; if invalid JSON, setUp will throw.
      expect(enArb, isNotEmpty);
      expect(viArb, isNotEmpty);
    });

    test('should have matching keys between English and Vietnamese', () {
      final enKeys = enArb.keys.where((k) => !k.startsWith('@@')).toSet();
      final viKeys = viArb.keys.where((k) => !k.startsWith('@@')).toSet();

      final missingInVi = enKeys.difference(viKeys);
      final missingInEn = viKeys.difference(enKeys);

      expect(
        missingInVi,
        isEmpty,
        reason: 'English keys missing in Vietnamese ARB: $missingInVi',
      );
      expect(
        missingInEn,
        isEmpty,
        reason: 'Vietnamese keys missing in English ARB: $missingInEn',
      );
    });

    test('should have songCount key in both files', () {
      expect(enArb, containsPair('songCount', '{count} songs'));
      expect(viArb, containsPair('songCount', '{count} bài hát'));
    });

    test('should have all new localization keys', () {
      const newKeys = [
        'importSuccess',
        'importErrorWithMsg',
        'androidOnlyFeature',
        'cannotLoadLibraryDb',
      ];
      for (final key in newKeys) {
        expect(
          enArb.containsKey(key),
          isTrue,
          reason: 'Missing English ARB key: $key',
        );
        expect(
          viArb.containsKey(key),
          isTrue,
          reason: 'Missing Vietnamese ARB key: $key',
        );
      }
    });

    test('should not have placeholder values', () {
      enArb.forEach((key, value) {
        if (key.startsWith('@@')) return;
        expect(value, isA<String>(), reason: 'Key $key is not a string');
        expect(
          (value as String).contains('TODO'),
          isFalse,
          reason: 'Key $key contains placeholder TODO',
        );
        expect(value.trim(), isNotEmpty, reason: 'Key $key has empty value');
      });
    });
  });
}
