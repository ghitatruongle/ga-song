/// Backwards-compatible re-export shim.
///
/// The structured [AppLogger] now lives at `lib/core/logging/app_logger.dart`
/// with a static (singleton) facade. This file is kept so any old import path
/// `import 'package:ga_song/core/app_logger.dart';` still resolves to the new
/// API. New code should import from the canonical location.
library;

export 'logging/app_logger.dart';
