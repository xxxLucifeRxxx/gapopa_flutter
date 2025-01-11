import 'package:flutter/material.dart';

import 'views/dock/widget_dock.dart';
import 'views/dock/widget_dock_item.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: WidgetDock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return WidgetDockItem(
                color: Colors.primaries[e.hashCode % Colors.primaries.length],
                icon: e,
              );
            },
          ),
        ),
      ),
    );
  }
}
