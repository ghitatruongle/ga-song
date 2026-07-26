import 'package:ga_song/core/services/db_service_wrapper.dart';

/// Mock implementation of [DatabaseServiceWrapper] for testing.
class MockDatabaseServiceWrapper implements DatabaseServiceWrapper {
  @override
  Future<void> incrementPlayCount(int songId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
