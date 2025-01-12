import 'dart:ui';

import 'package:flutter/material.dart';

import 'widget_dock_container.dart';
import 'widget_dock_item.dart';

const double baseWidthItem = 48;
const double baseHeightItem = 48;
const double itemSpacing = 16;
const double borderRadius = 8;

/// Dock of the reorderable [items].
class WidgetDock<T> extends StatefulWidget {
  const WidgetDock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [WidgetDock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<WidgetDock<T>> createState() => _WidgetDockState<T>();
}

/// State of the [WidgetDock] used to manipulate the [_items].
class _WidgetDockState<T> extends State<WidgetDock<T>>
    with SingleTickerProviderStateMixin {
  late final DockAnimationController _animationController;
  late final DockStateController _stateController;

  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  int? hoveredIndex;
  double baseTranslationY = 0;

  @override
  void initState() {
    super.initState();
    _animationController = DockAnimationController(this);
    _stateController = DockStateController(_items);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double getScaledSize(int index) {
    return getPropertyValue(
      index: index,
      baseValue: baseHeightItem,
      maxValue: 55,
      nonHoveredMaxValue: 52,
    );
  }

  double getTranslationY(int index) {
    return getPropertyValue(
      index: index,
      baseValue: baseTranslationY,
      maxValue: -14,
      nonHoveredMaxValue: -14,
    );
  }

  double getPropertyValue({
    required int index,
    required double baseValue,
    required double maxValue,
    required double nonHoveredMaxValue,
  }) {
    late final double propertyValue;

    if (hoveredIndex == null) {
      return baseValue;
    }

    final difference = (hoveredIndex! - index).abs();

    final itemsAffected = _items.length;

    if (difference == 0) {
      propertyValue = maxValue;

    } else if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;

      propertyValue = lerpDouble(baseValue, nonHoveredMaxValue, ratio)!;

    } else {
      propertyValue = baseValue;
    }

    return propertyValue;
  }


  @override
  Widget build(BuildContext context) {
    return WidgetDockContainer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_items.length, (index) {
          return Row(
            children: [
              buildAnimatedItem(index),
              if (index < _items.length - 1 &&
                  _stateController.draggedIndex != index)
                const SizedBox(width: itemSpacing),
            ],
          );
        }),
      ),
    );
  }

  Widget buildAnimatedItem(int index) {
    return AnimatedSlide(
      duration: Duration(
          milliseconds: _stateController.targetIndex != null ? 200 : 0),
      offset: DockPositionController.calculateOffset(
        index,
        _stateController.draggedIndex,
        _stateController.targetIndex,
        _stateController.isOutsideDock,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..translate(
            0.0,
            getTranslationY(index),
            0.0,
          ),
        width: _stateController.shouldShrink(index) ? 0 : getScaledSize(index),
        height: getScaledSize(index),
        child: buildDraggableItem(index),
      ),
    );
  }

  Widget buildDraggableItem(int index) {
    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _animationController.scaleAnimation,
          child: WidgetDockItem(
            icon: _stateController.items[index],
            color: Colors.primaries[_stateController.items[index].hashCode %
                Colors.primaries.length],
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: itemSpacing / 2,
        ),
      ),
      onDragStarted: () {
        setState(() {
          _stateController.handleDragStart(index);
          hoveredIndex = index;
        });
        _animationController.forward();
      },
      onDragEnd: (details) {
        _animationController.reverse();
        setState(() {
          _stateController.handleDragEnd();
          hoveredIndex = null;
        });
      },
      onDragUpdate: handleDragUpdate,
      child: buildDragTarget(index),
    );
  }

  Widget buildDragTarget(int index) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        setState(() {
          _stateController.reorderItems(details.data, index);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _stateController.isDragging &&
                  _stateController.draggedIndex == index
              ? 0.0
              : 1.0,
          child: WidgetDockItem(
            icon: _stateController.items[index],
            color: Colors.primaries[_stateController.items[index].hashCode %
                Colors.primaries.length],
          ),
        );
      },
    );
  }

  void handleDragUpdate(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final bool isOutside = !box.size.contains(localPosition);

    if (isOutside != _stateController.isOutsideDock) {
      setState(() {
        _stateController.isOutsideDock = isOutside;
        hoveredIndex = null;
      });
    }

    if (!isOutside) {
      DockPositionController.updateTargetIndex(
        localPosition,
        _stateController.draggedIndex,
        _stateController.items.length,
        (index) {
          hoveredIndex = index;

          if (_stateController.targetIndex != index) {
            setState(() {
              _stateController.targetIndex = index;
            });
          }
        },
      );
    }
  }
}

class DockAnimationController {
  final AnimationController controller;
  late final Animation<double> scaleAnimation;

  DockAnimationController(TickerProvider vsync)
      : controller = AnimationController(
          duration: const Duration(milliseconds: 200),
          vsync: vsync,
        ) {
    scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(controller);
  }

  void dispose() {
    controller.dispose();
  }

  void forward() => controller.forward();
  void reverse() => controller.reverse();
}

class DockPositionController {
  static Offset calculateOffset(
      int index, int? draggedIndex, int? targetIndex, bool isOutsideDock) {
    if (draggedIndex == null || targetIndex == null || isOutsideDock) {
      return Offset.zero;
    }

    if (draggedIndex < targetIndex) {
      if (index > draggedIndex && index <= targetIndex) {
        return const Offset(-1.0, 0.0);
      }
    } else if (draggedIndex > targetIndex) {
      if (index < draggedIndex && index >= targetIndex) {
        return const Offset(1.0, 0.0);
      }
    }
    return Offset.zero;
  }

  static void updateTargetIndex(
    Offset position,
    int? draggedIndex,
    int itemsLength,
    Function(int) onTargetIndexChanged,
  ) {
    if (draggedIndex == null) return;

    final double dx = position.dx;
    for (int i = 0; i < itemsLength; i++) {
      final double itemStart = i * (baseWidthItem + itemSpacing);
      final double itemCenter = itemStart + (baseWidthItem + itemSpacing) / 2;

      if (dx < itemCenter) {
        onTargetIndexChanged(i);
        return;
      }
    }

    onTargetIndexChanged(itemsLength - 1);
  }
}

class DockStateController<T> {
  final List<T> items;
  int? draggedIndex;
  int? targetIndex;
  bool isOutsideDock = false;
  bool isDragging = false;

  DockStateController(this.items);

  void handleDragStart(int index) {
    draggedIndex = index;
    targetIndex = index;
    isDragging = true;
  }

  void handleDragEnd() {
    if (targetIndex != null && !isOutsideDock) {
      final item = items.removeAt(draggedIndex!);
      items.insert(targetIndex!, item);
    }
    targetIndex = null;
    draggedIndex = null;
    isOutsideDock = false;
    isDragging = false;
  }

  bool shouldShrink(int index) {
    return draggedIndex == index && isOutsideDock && isDragging;
  }

  void reorderItems(int fromIndex, int toIndex) {
    if (fromIndex < toIndex) {
      toIndex -= 1;
    }
    final item = items.removeAt(fromIndex);
    items.insert(toIndex, item);
  }
}
