import 'package:flutter/material.dart';

import '../../core/theme_utils.dart';
import '../../l10n/app_localizations.dart';

class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.library_music_rounded,
            size: 80,
            color: context.adaptive.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noSongsYet,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.adaptive.withValues(alpha: 0.9),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: context.adaptive.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.cannotLoadLibrary,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.adaptive.withValues(alpha: 0.9),
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
