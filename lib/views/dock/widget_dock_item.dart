import 'package:flutter/material.dart';

import 'widget_dock.dart';

class WidgetDockItem extends StatelessWidget {
  final IconData icon;
  final Color color;

  const WidgetDockItem({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: baseWidthItem),
      width: baseWidthItem,
      height: baseHeightItem,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: color,
      ),
      child: Center(
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
