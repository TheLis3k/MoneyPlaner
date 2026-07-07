import 'package:flutter/material.dart';

import '../models/category.dart';

/// Resolves the string `color`/`icon` stored on a [Category] into real Flutter
/// values, with sensible fallbacks so bad data never crashes the UI.
extension CategoryVisuals on Category {
  Color get displayColor {
    var hex = color.replaceFirst('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex'; // add opaque alpha
    final value = int.tryParse(hex, radix: 16);
    return value == null ? Colors.blueGrey : Color(value);
  }

  IconData get displayIcon => _iconKeys[icon] ?? Icons.label_outline;
}

const _iconKeys = <String, IconData>{
  'home': Icons.home_outlined,
  'restaurant': Icons.restaurant_outlined,
  'directions_bus': Icons.directions_bus_outlined,
  'savings': Icons.savings_outlined,
  'celebration': Icons.celebration_outlined,
  'shopping_cart': Icons.shopping_cart_outlined,
  'health': Icons.favorite_outline,
  'bolt': Icons.bolt_outlined,
};
