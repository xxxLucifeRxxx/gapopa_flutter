// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'widget_dock.dart';

class WidgetDockContainer extends StatelessWidget {
  final Widget child;

  const WidgetDockContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(itemSpacing / 2),
      constraints: const BoxConstraints(
        minHeight: baseHeight + 16,
        maxHeight: baseHeight + 16,
      ),
      child: child,
    );
  }
}
