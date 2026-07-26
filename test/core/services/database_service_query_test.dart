import 'package:ga_song/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/services/db_service_wrapper.dart';
import 'package:ga_song/core/utils/result.dart';
import 'package:ga_song/core/exceptions/app_exception.dart' as app_exc;

void main() {
  // Required for tests running on desktop platforms (Linux/Windows/macOS).
  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  group('DatabaseServiceWrapper.querySongs', () {
    late DatabaseServiceWrapper service;

    setUp(() async {
      service = DatabaseServiceWrapper(AppDatabase(executor: NativeDatabase.memory()));
      await service.init();
    });

    tearDown(() async {
      service.dispose();
    });

    test('returns Success with list after init', () async {
      final result = await service.querySongs();
      expect(result, isA<Success<List<dynamic>>>());
    });

    test('Failure carries AppException in exception field', () {
      // Type-level test: ensure Failure can carry AppException via [exception].
      final failure = Failure<dynamic>(
        'database error',
        StackTrace.current,
        const app_exc.DatabaseException('boom'),
      );
      expect(failure.exception, isA<app_exc.AppException>());
      expect((failure.exception as app_exc.AppException).message, 'boom');
    });
  });
}
