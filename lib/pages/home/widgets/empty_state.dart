import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState({super.key, required this.icon, required this.title, required this.message});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).hintColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$title\n$message', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}