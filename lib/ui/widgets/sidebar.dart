import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../core/audio/audio_engine_service.dart';
import '../../core/settings_manager.dart';
import '../../core/theme_utils.dart';

enum TabItem { home, library, online, ktv, personal, settings }

// ─── Layout Constants ────────────────────────────────────────────────────────
// Public so other widgets (e.g. home_screen.dart overlay layers) can
// align to the sidebar without duplicating the magic numbers.
const double kSidebarExpandedWidth = 220.0;
const double kSidebarCollapsedWidth = 64.0;
const double _kItemHeight = 40.0;
const double _kActiveIndicatorWidth = 3.0;
const Duration _kCollapseDuration = Duration(milliseconds: 250);
const Duration _kHoverDuration = Duration(milliseconds: 150);

class SidebarWidget extends ConsumerStatefulWidget {
  final TabItem currentTab;
  final ValueChanged<TabItem> onTabChanged;
  final VoidCallback? onImportMusic;
  final VoidCallback? onManagePlaylists;
  final ValueChanged<String>? onSmartPlaylistSelected;

  const SidebarWidget({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.onImportMusic,
    this.onManagePlaylists,
    this.onSmartPlaylistSelected,
  });

  @override
  ConsumerState<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends ConsumerState<SidebarWidget> {
  late final SettingsManager _settingsManager;

  @override
  void initState() {
    super.initState();
    _settingsManager = ref.read(settingsManagerProvider);
  }

  void _toggleCollapse() {
    final current = _settingsManager.sidebarCollapsedNotifier.value;
    _settingsManager.setSidebarCollapsed(!current);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.adaptive;

    return ValueListenableBuilder<bool>(
      valueListenable: _settingsManager.sidebarCollapsedNotifier,
      builder: (context, isCollapsed, _) {
        return AnimatedContainer(
          duration: _kCollapseDuration,
          curve: Curves.easeInOut,
          width: isCollapsed ? kSidebarCollapsedWidth : kSidebarExpandedWidth,
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────────────────────────
              _SidebarHeader(
                isCollapsed: isCollapsed,
                textColor: textColor,
                onToggle: _toggleCollapse,
              ),

              const SizedBox(height: 8),

              // ─── Main Navigation ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 8 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SidebarMenuItem(
                        icon: Icons.home_filled,
                        title: 'Trang chủ',
                        tab: TabItem.home,
                        currentTab: widget.currentTab,
                        onTabChanged: widget.onTabChanged,
                        isCollapsed: isCollapsed,
                      ),
                      _SidebarMenuItem(
                        icon: Icons.library_music_outlined,
                        title: 'Thư viện',
                        tab: TabItem.library,
                        currentTab: widget.currentTab,
                        onTabChanged: widget.onTabChanged,
                        isCollapsed: isCollapsed,
                      ),
                      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                        _SidebarMenuItem(
                          icon: Icons.language_rounded,
                          title: 'Online',
                          tab: TabItem.online,
                          currentTab: widget.currentTab,
                          onTabChanged: widget.onTabChanged,
                          isCollapsed: isCollapsed,
                        ),

                      // ─── Separator ───────────────────────────────────────
                      _SidebarSeparator(
                        isCollapsed: isCollapsed,
                        label: isCollapsed ? null : 'PHÒNG NGHE NHẠC',
                        textColor: textColor,
                      ),

                      _SidebarMenuItem(
                        icon: Icons.mic_external_on_rounded,
                        title: 'KTV',
                        tab: TabItem.ktv,
                        currentTab: widget.currentTab,
                        onTabChanged: widget.onTabChanged,
                        isCollapsed: isCollapsed,
                      ),
                      _SidebarMenuItem(
                        icon: Icons.graphic_eq_rounded,
                        title: 'Visualizer',
                        tab: TabItem.personal,
                        currentTab: widget.currentTab,
                        onTabChanged: widget.onTabChanged,
                        isCollapsed: isCollapsed,
                        showNowPlaying: true,
                      ),

                      // ─── Smart Playlists ─────────────────────────────────
                      if (widget.onSmartPlaylistSelected != null) ...[
                        _SidebarSeparator(
                          isCollapsed: isCollapsed,
                          label: isCollapsed ? null : 'PLAYLIST THÔNG MINH',
                          textColor: textColor,
                        ),
                        _SidebarSmartPlaylistItem(
                          icon: '🔥',
                          title: 'Nghe nhiều nhất',
                          type: 'mostPlayed',
                          isCollapsed: isCollapsed,
                          onTap: widget.onSmartPlaylistSelected,
                        ),
                        _SidebarSmartPlaylistItem(
                          icon: '🕐',
                          title: 'Nghe gần đây',
                          type: 'recentlyPlayed',
                          isCollapsed: isCollapsed,
                          onTap: widget.onSmartPlaylistSelected,
                        ),
                        _SidebarSmartPlaylistItem(
                          icon: '❤️',
                          title: 'Yêu thích',
                          type: 'favorites',
                          isCollapsed: isCollapsed,
                          onTap: widget.onSmartPlaylistSelected,
                        ),
                        _SidebarSmartPlaylistItem(
                          icon: '🆕',
                          title: 'Thêm gần đây',
                          type: 'recentlyAdded',
                          isCollapsed: isCollapsed,
                          onTap: widget.onSmartPlaylistSelected,
                        ),
                        _SidebarSmartPlaylistItem(
                          icon: '🎲',
                          title: 'Khám phá',
                          type: 'discovery',
                          isCollapsed: isCollapsed,
                          onTap: widget.onSmartPlaylistSelected,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ─── Footer ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCollapsed ? 8 : 12, 0, isCollapsed ? 8 : 12, 8,
                ),
                child: Column(
                  children: [
                    _SidebarSeparator(
                      isCollapsed: isCollapsed,
                      label: null,
                      textColor: textColor,
                    ),
                    if (!isCollapsed) ...[
                      _SidebarActionButton(
                        icon: Icons.add_rounded,
                        title: 'Import nhạc',
                        onPressed: widget.onImportMusic,
                      ),
                      _SidebarActionButton(
                        icon: Icons.playlist_add_rounded,
                        title: 'Quản lý Playlist',
                        onPressed: widget.onManagePlaylists,
                      ),
                      const SizedBox(height: 4),
                    ] else ...[
                      _SidebarIconButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Import nhạc',
                        onPressed: widget.onImportMusic,
                        textColor: textColor,
                      ),
                      _SidebarIconButton(
                        icon: Icons.playlist_add_rounded,
                        tooltip: 'Quản lý Playlist',
                        onPressed: widget.onManagePlaylists,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 4),
                    ],
                    _SidebarMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Cài đặt',
                      tab: TabItem.settings,
                      currentTab: widget.currentTab,
                      onTabChanged: widget.onTabChanged,
                      isCollapsed: isCollapsed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  final bool isCollapsed;
  final Color textColor;
  final VoidCallback onToggle;

  const _SidebarHeader({
    required this.isCollapsed,
    required this.textColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCollapsed ? 12 : 20,
        36,
        isCollapsed ? 12 : 16,
        12,
      ),
      child: isCollapsed
          ? Center(
              child: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  Icons.music_note_rounded,
                  color: textColor,
                  size: 24,
                ),
              ),
            )
          : Row(
              children: [
                Icon(
                  Icons.music_note_rounded,
                  color: textColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AutoGreetingText(
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
                GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: textColor.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Separator ───────────────────────────────────────────────────────────────

class _SidebarSeparator extends StatelessWidget {
  final bool isCollapsed;
  final String? label;
  final Color textColor;

  const _SidebarSeparator({
    required this.isCollapsed,
    this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: isCollapsed ? 4 : 8,
      ),
      child: Column(
        children: [
          Divider(
            color: textColor.withValues(alpha: 0.08),
            height: 1,
          ),
          if (label != null && !isCollapsed) ...[
            const SizedBox(height: 8),
            Text(
              label!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.35),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Menu Item ───────────────────────────────────────────────────────────────

class _SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final TabItem tab;
  final TabItem currentTab;
  final ValueChanged<TabItem> onTabChanged;
  final bool isCollapsed;
  final bool showNowPlaying;

  const _SidebarMenuItem({
    required this.icon,
    required this.title,
    required this.tab,
    required this.currentTab,
    required this.onTabChanged,
    required this.isCollapsed,
    this.showNowPlaying = false,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = context.adaptive;
    final isSelected = widget.currentTab == widget.tab;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTabChanged(widget.tab),
        child: AnimatedContainer(
          duration: _kHoverDuration,
          height: _kItemHeight,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: _isHovered && !isSelected
                ? textColor.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Active indicator (hidden when collapsed to avoid 3px overflow)
              if (!widget.isCollapsed)
                AnimatedContainer(
                  duration: _kHoverDuration,
                  width: _kActiveIndicatorWidth,
                  height: isSelected ? 20 : 0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

              // Icon
              SizedBox(
                width: widget.isCollapsed ? 48 : 40,
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: isSelected
                      ? textColor
                      : textColor.withValues(alpha: 0.55),
                ),
              ),

              // Title (only when expanded)
              if (!widget.isCollapsed) ...[
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? textColor
                          : textColor.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Now playing indicator
                if (widget.showNowPlaying)
                  _NowPlayingIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Icon Button (collapsed mode) ────────────────────────────────────────────

class _SidebarIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color textColor;

  const _SidebarIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    required this.textColor,
  });

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: _kHoverDuration,
            height: _kItemHeight,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.textColor.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.textColor.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ───────────────────────────────────────────────────────────

class _SidebarActionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onPressed;

  const _SidebarActionButton({
    required this.icon,
    required this.title,
    this.onPressed,
  });

  @override
  State<_SidebarActionButton> createState() => _SidebarActionButtonState();
}

class _SidebarActionButtonState extends State<_SidebarActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = context.adaptive;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: _kHoverDuration,
          height: _kItemHeight,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? textColor.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: textColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Now Playing Indicator ───────────────────────────────────────────────────

class _NowPlayingIndicator extends StatefulWidget {
  @override
  State<_NowPlayingIndicator> createState() => _NowPlayingIndicatorState();
}

class _NowPlayingIndicatorState extends State<_NowPlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        // Phase 2.2: read engine state from state provider.
        final engineState = ref.watch(engineStateProvider);
        final isPlaying = engineState == AudioEngineState.playing;
        if (!isPlaying) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.5 + _controller.value * 0.5,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Auto Greeting Text ──────────────────────────────────────────────────────

class _AutoGreetingText extends StatefulWidget {
  final Color color;
  const _AutoGreetingText({required this.color});

  @override
  State<_AutoGreetingText> createState() => _AutoGreetingTextState();
}

class _AutoGreetingTextState extends State<_AutoGreetingText> {
  late String _greeting;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _greeting = _getGreeting();
    _scheduleNextGreetingChange();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNextGreetingChange() {
    _timer?.cancel();
    final now = DateTime.now();
    final nextChange = _getNextChangeTime(now);
    final delay = nextChange.difference(now);

    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _greeting = _getGreeting();
      });
      _scheduleNextGreetingChange();
    });
  }

  DateTime _getNextChangeTime(DateTime now) {
    if (now.hour < 12) {
      return DateTime(now.year, now.month, now.day, 12, 0, 0);
    } else if (now.hour < 18) {
      return DateTime(now.year, now.month, now.day, 18, 0, 0);
    } else {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _greeting,
      style: TextStyle(fontSize: 11, color: widget.color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─── Smart Playlist Item ─────────────────────────────────────────────────────

class _SidebarSmartPlaylistItem extends StatefulWidget {
  final String icon;
  final String title;
  final String type;
  final bool isCollapsed;
  final ValueChanged<String>? onTap;

  const _SidebarSmartPlaylistItem({
    required this.icon,
    required this.title,
    required this.type,
    required this.isCollapsed,
    this.onTap,
  });

  @override
  State<_SidebarSmartPlaylistItem> createState() => _SidebarSmartPlaylistItemState();
}

class _SidebarSmartPlaylistItemState extends State<_SidebarSmartPlaylistItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = context.adaptive;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap?.call(widget.type),
        child: AnimatedContainer(
          duration: _kHoverDuration,
          height: _kItemHeight,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: _isHovered
                ? textColor.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Active indicator spacer (hidden when collapsed to avoid overflow)
              if (!widget.isCollapsed)
                const SizedBox(width: _kActiveIndicatorWidth),

              // Icon (emoji)
              SizedBox(
                width: widget.isCollapsed ? 48 : 40,
                child: Text(
                  widget.icon,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

              // Title (only when expanded)
              if (!widget.isCollapsed)
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: textColor.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
