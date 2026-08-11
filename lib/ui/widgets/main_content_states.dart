import 'package:flutter/material.dart';

import '../../core/theme_utils.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({super.key});

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Soft accent circle behind icon — Spotify-style depth
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.library_music_rounded,
              size: 48,
              color: accentColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.noSongsYet,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.adaptive.withValues(alpha: 0.9),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.addSongsHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: context.adaptive.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorLoadingState extends StatelessWidget {
  const ErrorLoadingState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.danger.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.cannotLoadLibrary,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.adaptive.withValues(alpha: 0.9),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.adaptive.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
