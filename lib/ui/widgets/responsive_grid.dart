import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';

/// A responsive grid that adapts column count based on screen width.
///
/// Automatically adjusts from 2 columns on mobile to 5 columns on large desktop.
class ResponsiveGrid extends StatelessWidget {
  /// The children to display in the grid.
  final List<Widget> children;

  /// Spacing between columns.
  final double crossAxisSpacing;

  /// Spacing between rows.
  final double mainAxisSpacing;

  /// Child aspect ratio (width / height).
  final double childAspectRatio;

  /// Padding around the grid.
  final EdgeInsets? padding;

  /// Creates a responsive grid.
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio = 1,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = Breakpoints.gridColumns(constraints.maxWidth);

        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
