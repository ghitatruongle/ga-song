import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppLocalizations', () {
    late AppLocalizations vi;
    late AppLocalizations en;

    setUp(() {
      vi = AppLocalizations(const Locale('vi'));
      en = AppLocalizations(const Locale('en'));
    });

    test('should return Vietnamese for unsupported locale', () {
      final l10n = AppLocalizations(const Locale('fr'));
      expect(l10n.home, 'Trang chủ');
    });

    test('should return English for en locale', () {
      expect(en.home, 'Home');
      expect(en.library, 'Library');
      expect(en.settings, 'Settings');
    });

    test('should return Vietnamese for vi locale', () {
      expect(vi.home, 'Trang chủ');
      expect(vi.library, 'Thư viện');
      expect(vi.settings, 'Cài đặt');
    });

    test('translateWith should replace parameters', () {
      final result = en.translateWith('songCount', {'count': '5'});
      expect(result, '5 songs');
    });

    test('translateWith should replace parameters in Vietnamese', () {
      final result = vi.translateWith('songCount', {'count': '5'});
      expect(result, '5 bài hát');
    });

    test('translateWith should handle multiple parameters', () {
      final result = en.translateWith('importErrorWithMsg', {
        'error': 'File not found',
      });
      expect(result, 'Import error: File not found');
    });

    test('translate should return key as fallback for missing key', () {
      expect(vi.translate('nonExistentKey'), 'nonExistentKey');
    });

    test('all convenience getters return non-empty for Vietnamese', () {
      final getters = _allGetterValues(vi);
      for (final value in getters) {
        expect(value, isNotEmpty, reason: 'Getter returned empty string');
      }
    });

    test('all convenience getters return non-empty for English', () {
      final getters = _allGetterValues(en);
      for (final value in getters) {
        expect(value, isNotEmpty, reason: 'Getter returned empty string');
      }
    });
  });
}

/// Helper to collect all AppLocalizations getter values.
List<String> _allGetterValues(AppLocalizations l10n) => [
  l10n.appTitle,
  l10n.home,
  l10n.library,
  l10n.online,
  l10n.ktv,
  l10n.personal,
  l10n.settings,
  l10n.play,
  l10n.pause,
  l10n.next,
  l10n.previous,
  l10n.shuffle,
  l10n.repeat,
  l10n.repeatOne,
  l10n.playOneStop,
  l10n.noSongSelected,
  l10n.noLyrics,
  l10n.search,
  l10n.import,
  l10n.addToPlaylist,
  l10n.createPlaylist,
  l10n.deletePlaylist,
  l10n.favorites,
  l10n.speed,
  l10n.equalizer,
  l10n.sleepTimer,
  l10n.volume,
  l10n.lyrics,
  l10n.miniPlayer,
  l10n.pip,
  l10n.errorInit,
  l10n.errorRestart,
  l10n.permissionMic,
  l10n.permissionDenied,
  l10n.greetingMorning,
  l10n.greetingAfternoon,
  l10n.greetingEvening,
  l10n.musicRoom,
  l10n.synced,
  l10n.offsetReset,
  l10n.noPlaylist,
  l10n.addAlbumField,
  l10n.noSongPlaying,
  l10n.exitMusicRoom,
  l10n.closeMiniPlayer,
  l10n.restoreNormal,
  l10n.find,
  l10n.nowPlaying,
  l10n.guide,
  l10n.guideContent,
  l10n.playing,
  l10n.hideVideo,
  l10n.showVideo,
  l10n.importError,
  l10n.unknown,
  l10n.bassBoost,
  l10n.reverb,
  l10n.compressor,
  l10n.normalization,
  l10n.pitchShift,
  l10n.cancel,
  l10n.save,
  l10n.delete,
  l10n.confirm,
  l10n.sortBy,
  l10n.sortByName,
  l10n.sortByArtist,
  l10n.sortByAlbum,
  l10n.sortByDate,
  l10n.sortByDuration,
  l10n.appearance,
  l10n.audio,
  l10n.shortcuts,
  l10n.advanced,
  l10n.noSongsYet,
  l10n.addSongsHint,
  l10n.cannotLoadLibrary,
  l10n.retry,
  l10n.allSongs,
  l10n.importSuccess,
  l10n.androidOnlyFeature,
  l10n.cannotLoadLibraryDb,
];
