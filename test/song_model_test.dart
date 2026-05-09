import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/song_model.dart';

void main() {
  test('SongModel repairs mojibake text loaded from songs.json', () {
    const expectedName = 'Kh\u00F4ng Ng\u1EEBng Suy Ngh\u0129';
    const expectedArtist = 'D\u01B0\u01A1ng Domic';

    final song = SongModel.fromJson(<String, dynamic>{
      'name': _toMojibake(_toMojibake(expectedName)),
      'fileName': 'khong_ngung_suy_nghi.mp3',
      'artist': _toMojibake(_toMojibake(expectedArtist)),
    });

    expect(song.name, expectedName);
    expect(song.artist, expectedArtist);
  });
}

String _toMojibake(String value) {
  return latin1.decode(utf8.encode(value));
}
