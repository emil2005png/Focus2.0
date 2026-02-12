import 'package:flutter/material.dart';

class Badge {
  final String id;
  final String name;
  final String icon;
  final String description;
  final Color color;
  final bool isEarned;

  Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
    this.isEarned = false,
  });
}
