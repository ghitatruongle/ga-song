// Copyright 2024 G.A - Song. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Platform interface for Windows Jump List operations.
///
/// This defines the contract that platform-specific implementations
/// (Windows, macOS, Linux) must fulfill for Jump List integration.

import 'package:flutter/foundation.dart';

import '../../models/playlist.dart';
import '../../models/song.dart';

/// Platform interface for Jump List operations.
abstract class JumpListPlatform {
  /// Initialize the Jump List service.
  Future<void> initialize();

  /// Set the list of Jump List items.
  Future<void> setJumpListItems(List<JumpListItem> items);

  /// Add a single item to the Jump List.
  Future<void> addItem(JumpListItem item);

  /// Remove an item from the Jump List.
  Future<void> removeItem(String itemId);

  /// Clear all items from the Jump List.
  Future<void> clear();

  /// Set the list of tasks (common actions like Play, Pause, etc.)
  Future<void> setTasks(List<JumpListTask> tasks);

  /// Dispose of resources.
  void dispose();
}

/// Represents a Jump List item.
@immutable
class JumpListItem {
  const JumpListItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.iconPath,
    required this.type,
    this.arguments = const {},
    this.pinned = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? iconPath;
  final JumpListItemType type;
  final Map<String, dynamic> arguments;
  final bool pinned;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'iconPath': iconPath,
      'type': type.name,
      'arguments': arguments,
      'pinned': pinned,
    };
  }
}

enum JumpListItemType {
  recent,
  pinned,
  task,
}

/// Represents a Jump List task (common action).
@immutable
class JumpListTask {
  const JumpListTask({
    required this.id,
    required this.title,
    this.iconPath,
    required this.arguments,
  });

  final String id;
  final String title;
  final String? iconPath;
  final Map<String, dynamic> arguments;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconPath': iconPath,
      'arguments': arguments,
    };
  }
}

/// Factory for creating platform-specific JumpListPlatform implementations.
class JumpListPlatformFactory {
  static JumpListPlatform? _instance;

  /// Get the platform-specific implementation.
  static JumpListPlatform get instance {
    if (_instance != null) return _instance!;

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      _instance = MacOSJumpListPlatform();
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      _instance = LinuxJumpListPlatform();
    } else {
      // Windows and others: use the stub for now. The full Windows Jump
      // List native implementation requires Win32 FFI bindings and is
      // handled separately (see jump_list_service).
      _instance = StubJumpListPlatform();
    }
    return _instance!;
  }

  /// Override the instance (useful for testing).
  static void setInstance(JumpListPlatform instance) {
    _instance = instance;
  }
}

/// Stub implementation for unsupported platforms.
class StubJumpListPlatform implements JumpListPlatform {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> setJumpListItems(List<JumpListItem> items) async {}

  @override
  Future<void> addItem(JumpListItem item) async {}

  @override
  Future<void> removeItem(String itemId) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> setTasks(List<JumpListTask> tasks) async {}

  @override
  void dispose() {}
}

/// macOS implementation (uses Dock menu).
class MacOSJumpListPlatform implements JumpListPlatform {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> setJumpListItems(List<JumpListItem> items) async {}

  @override
  Future<void> addItem(JumpListItem item) async {}

  @override
  Future<void> removeItem(String itemId) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> setTasks(List<JumpListTask> tasks) async {}

  @override
  void dispose() {}
}

/// Linux implementation (uses .desktop file actions).
class LinuxJumpListPlatform implements JumpListPlatform {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> setJumpListItems(List<JumpListItem> items) async {}

  @override
  Future<void> addItem(JumpListItem item) async {}

  @override
  Future<void> removeItem(String itemId) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> setTasks(List<JumpListTask> tasks) async {}

  @override
  void dispose() {}
}