import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../core/services/database_service.dart';
import '../models/song.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());

final isarProvider = Provider<Isar>((ref) {
  return ref.watch(databaseServiceProvider).isar;
});

final songListProvider = StreamProvider<List<Song>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.songs.where().sortByDateAddedDesc().watch(fireImmediately: true);
});
