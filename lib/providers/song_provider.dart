import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import 'service_providers.dart';

final songListProvider = StreamProvider<List<Song>>((final ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.songsStream;
});
