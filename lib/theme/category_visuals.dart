import 'package:flutter/material.dart';

import '../models/category.dart';

/// Icon keys a user can choose from, mapped to their [IconData].
///
/// Stored as a string key on [Category] so the database stays icon-library
/// agnostic and the choice survives export/import.
const Map<String, IconData> categoryIcons = <String, IconData>{
  'home': Icons.home_outlined,
  'restaurant': Icons.restaurant_outlined,
  'directions_bus': Icons.directions_bus_outlined,
  'savings': Icons.savings_outlined,
  'celebration': Icons.celebration_outlined,
  'shopping_cart': Icons.shopping_cart_outlined,
  'health': Icons.favorite_outline,
  'bolt': Icons.bolt_outlined,
  'school': Icons.school_outlined,
  'pets': Icons.pets_outlined,
  'fitness': Icons.fitness_center_outlined,
  'flight': Icons.flight_outlined,
  'coffee': Icons.local_cafe_outlined,
  'phone': Icons.smartphone_outlined,
  'gift': Icons.card_giftcard_outlined,
  'work': Icons.work_outline,
  'child': Icons.child_care_outlined,
  'wifi': Icons.wifi_outlined,
  'car': Icons.directions_car_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
};

/// Default palette offered in the category color picker (Material-ish hues).
const List<String> categoryColorPalette = <String>[
  '#5C6BC0',
  '#66BB6A',
  '#FFA726',
  '#26A69A',
  '#EC407A',
  '#EF5350',
  '#AB47BC',
  '#42A5F5',
  '#8D6E63',
  '#78909C',
  '#FFCA28',
  '#9CCC65',
];

/// Resolves the string `color`/`icon` stored on a [Category] into real Flutter
/// values, with sensible fallbacks so bad data never crashes the UI.
extension CategoryVisuals on Category {
  Color get displayColor {
    var hex = color.replaceFirst('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex'; // add opaque alpha
    final value = int.tryParse(hex, radix: 16);
    return value == null ? Colors.blueGrey : Color(value);
  }

  IconData get displayIcon => categoryIcons[icon] ?? Icons.label_outline;
}
