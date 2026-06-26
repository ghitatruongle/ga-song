import 'package:ga_song/core/services/database_service.dart';

/// Mock implementation of [DatabaseService] for testing.
class MockDatabaseService implements DatabaseService {
  @override
  Future<void> incrementPlayCount(int songId) async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
