import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/service_locator.dart';
import '../../core/view_models/player_view_model.dart';
import '../../core/theme_utils.dart';

enum TabItem { home, library, online, ktv, personal, settings }

class SidebarWidget extends StatelessWidget {
  final TabItem currentTab;
  final ValueChanged<TabItem> onTabChanged;
  final VoidCallback? onImportMusic;
  final VoidCallback? onManagePlaylists;

  const SidebarWidget({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.onImportMusic,
    this.onManagePlaylists,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.adaptive;

    return Container(
      width: 240,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personalized User Header with dynamic greeting
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: textColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AutoGreetingText(
                        color: textColor.withValues(alpha: 0.6),
                      ),
                      Text(
                        'G.A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Menu Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarMenuItem(
                    icon: Icons.home_filled,
                    title: 'Trang chủ',
                    tab: TabItem.home,
                    currentTab: currentTab,
                    onTabChanged: onTabChanged,
                  ),
                  _SidebarMenuItem(
                    icon: Icons.library_music_outlined,
                    title: 'Thư viện',
                    tab: TabItem.library,
                    currentTab: currentTab,
                    onTabChanged: onTabChanged,
                  ),
                  // Online tab: chỉ hiện trên Android (youtube_player_iframe không hỗ trợ desktop)
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                    _SidebarMenuItem(
                      icon: Icons.language_rounded,
                      title: 'Online (YouTube)',
                      tab: TabItem.online,
                      currentTab: currentTab,
                      onTabChanged: onTabChanged,
                    ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'PHÒNG NGHE NHẠC',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor.withValues(alpha: 0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _SidebarMenuItem(
                    icon: Icons.mic_external_on_rounded,
                    title: 'Phòng Hát (KTV)',
                    tab: TabItem.ktv,
                    currentTab: currentTab,
                    onTabChanged: onTabChanged,
                  ),
                  _SidebarMenuItem(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Cá nhân (Visualizer)',
                    tab: TabItem.personal,
                    currentTab: currentTab,
                    onTabChanged: onTabChanged,
                    showNowPlaying: true,
                  ),
                ],
              ),
            ),
          ),
          // Footer actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                // Import music button
                _SidebarActionButton(
                  icon: Icons.add_rounded,
                  title: 'Import nhạc',
                  onPressed: onImportMusic,
                ),
                // Manage playlists button
                _SidebarActionButton(
                  icon: Icons.playlist_add_rounded,
                  title: 'Quản lý Playlist',
                  onPressed: onManagePlaylists,
                ),
                const SizedBox(height: 8),
                _SidebarMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt',
                  tab: TabItem.settings,
                  currentTab: currentTab,
                  onTabChanged: onTabChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact action button for sidebar (Import, Manage Playlist, etc.)
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: _isHovered
              ? textColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(widget.icon, color: textColor.withValues(alpha: 0.6), size: 20),
          title: Text(
            widget.title,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
          ),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          onTap: widget.onPressed,
        ),
      ),
    );
  }
}

/// Sidebar menu item with hover scale animation and optional now-playing indicator
class _SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final TabItem tab;
  final TabItem currentTab;
  final ValueChanged<TabItem> onTabChanged;
  final bool showNowPlaying;

  const _SidebarMenuItem({
    required this.icon,
    required this.title,
    required this.tab,
    required this.currentTab,
    required this.onTabChanged,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 8),
        transform: _isHovered && !isSelected
            ? Matrix4.diagonal3Values(1.05, 1.05, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? textColor.withValues(alpha: 0.15)
              : _isHovered
              ? textColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            widget.icon,
            color: isSelected ? textColor : textColor.withValues(alpha: 0.7),
            size: 22,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: isSelected
                        ? textColor
                        : textColor.withValues(alpha: 0.7),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Now playing pulsing dot
              if (widget.showNowPlaying)
                ListenableBuilder(
                  listenable: sl<PlayerViewModel>(),
                  builder: (context, _) {
                    if (sl<PlayerViewModel>().isPlaying) {
                      return _NowPlayingDot(
                        color: Theme.of(context).primaryColor,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          onTap: () => widget.onTabChanged(widget.tab),
        ),
      ),
    );
  }
}

/// Animated pulsing dot that indicates music is playing
class _NowPlayingDot extends StatefulWidget {
  final Color color;
  const _NowPlayingDot({required this.color});

  @override
  State<_NowPlayingDot> createState() => _NowPlayingDotState();
}

class _NowPlayingDotState extends State<_NowPlayingDot>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.5 + _controller.value * 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.3 + _controller.value * 0.3,
                ),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

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
      // Dùng .add(Duration(days: 1)) để tránh lỗi overflow qua ngày cuối tháng
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng,';
    if (hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }

  @override
  Widget build(BuildContext context) {
    return Text(_greeting, style: TextStyle(fontSize: 12, color: widget.color));
  }
}
