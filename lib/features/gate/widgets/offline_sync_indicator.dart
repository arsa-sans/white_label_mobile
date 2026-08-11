import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OfflineSyncIndicator extends StatelessWidget {
  final bool isOnline;
  const OfflineSyncIndicator({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOnline
            ? AppTheme.accentColor.withValues(alpha: 0.15)
            : AppTheme.warningColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? AppTheme.accentColor.withValues(alpha: 0.5)
              : AppTheme.warningColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.accentColor : AppTheme.warningColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isOnline ? AppTheme.accentColor : AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }
}
