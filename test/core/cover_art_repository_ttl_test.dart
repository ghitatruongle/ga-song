import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/cover_art_repository.dart';

void main() {
  test('CoverArtEntry exposes a capturedAt timestamp', () {
    final before = DateTime.now();
    final entry = _entryWith(
      fileName: 'a.png',
      imagePath: '/tmp/a.png',
      exists: true,
      isAsset: false,
    );
    final after = DateTime.now();
    expect(
      entry.capturedAt.isAfter(before.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(
      entry.capturedAt.isBefore(after.add(const Duration(seconds: 1))),
      isTrue,
    );
  });

  test('CoverArtEntry.isFresh returns true when within TTL', () {
    final entry = _entryWith(fileName: 'a.png', capturedAt: DateTime.now());
    expect(entry.isFresh(ttl: const Duration(minutes: 30)), isTrue);
  });

  test('CoverArtEntry.isFresh returns false when past TTL', () {
    final entry = _entryWith(
      fileName: 'a.png',
      capturedAt: DateTime.now().subtract(const Duration(minutes: 31)),
    );
    expect(entry.isFresh(ttl: const Duration(minutes: 30)), isFalse);
  });
}

CoverArtEntry _entryWith({
  required String fileName,
  DateTime? capturedAt,
  String imagePath = '/tmp/x.png',
  bool exists = true,
  bool isAsset = false,
}) {
  return CoverArtEntry(
    fileName: fileName,
    imagePath: imagePath,
    exists: exists,
    isAsset: isAsset,
    tier: CoverArtCacheTier.memory,
    capturedAt: capturedAt,
  );
}
