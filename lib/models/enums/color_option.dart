import 'package:flutter/material.dart';

/// Manages enumertion defining supported valid scenario colors for graph line.
/// * [label] - User readable label matching enumerated color.
/// * [colorIndex] - Value representing the index of the color in the list.
/// * [color] - Cooresponding material [Color] value.
enum ColorOption {
  blue(   0, Colors.blue,   'Blue'),
  green(  1, Colors.green,  'Green'),
  red(    2, Colors.red,    'Red'),
  purple( 3, Colors.purple, 'Purple'),
  orange( 4, Colors.orange, 'Orange');

  final int colorIndex;
  final Color color;
  final String label;

  const ColorOption(this.colorIndex, this.color, this.label);

  /// Returns the enumeration whose [label] matches the specified [target] string.
  /// Returns ColorOption.blue if the label cannot be found.
  factory ColorOption.fromLabel(String target) {
    for (var enumItem in ColorOption.values) {
      if (enumItem.label == target) return enumItem;
    }
    return ColorOption.blue;
  }

  /// Returns the enumeration whose [label] matches the specified [target] color index.
  /// Returns null is the index could not be found.
  static ColorOption? fromColorIndex(int target) {
    for (var enumItem in ColorOption.values) {
      if (enumItem.colorIndex == target) return enumItem;
    }
    return null;
  } 
}