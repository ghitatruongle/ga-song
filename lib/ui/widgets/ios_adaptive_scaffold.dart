import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar.dart';
import '../widgets/mobile_mini_player_bar.dart';

class IOSAdaptiveScaffold extends ConsumerWidget {
  final Widget body;
  final TabItem currentTab;
  final ValueChanged<TabItem> onTabSelected;

  const IOSAdaptiveScaffold({
    super.key,
    required this.body,
    required this.currentTab,
    required this.onTabSelected,
  });

  bool get _isMobileLayout {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (!_isMobileLayout) {
      return Scaffold(body: body);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(top: false, child: body),
      bottomNavigationBar: Container(
        color: Colors.black.withValues(alpha: 0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: MobileMiniPlayerBar(),
            ),
            CupertinoTabBar(
              currentIndex: _getTabIndex(currentTab),
              onTap: (final index) => onTabSelected(_getTabFromIndex(index)),
              activeColor: const Color(0xFF1DB954),
              inactiveColor: Colors.grey,
              backgroundColor: Colors.transparent,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.house_fill),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.music_albums_fill),
                  label: 'Thư viện',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.mic_fill),
                  label: 'KTV',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.globe),
                  label: 'Khám phá',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.settings),
                  label: 'Cài đặt',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getTabIndex(final TabItem tab) {
    switch (tab) {
      case TabItem.home:
        return 0;
      case TabItem.library:
        return 1;
      case TabItem.ktv:
        return 2;
      case TabItem.online:
        return 3;
      case TabItem.settings:
        return 4;
      default:
        return 0;
    }
  }

  TabItem _getTabFromIndex(final int index) {
    switch (index) {
      case 0:
        return TabItem.home;
      case 1:
        return TabItem.library;
      case 2:
        return TabItem.ktv;
      case 3:
        return TabItem.online;
      case 4:
        return TabItem.settings;
      default:
        return TabItem.home;
    }
  }
}
