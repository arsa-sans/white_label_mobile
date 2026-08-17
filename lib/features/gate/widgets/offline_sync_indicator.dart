import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OfflineSyncIndicator extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final VoidCallback? onSyncTap;

  const OfflineSyncIndicator({
    super.key,
    required this.isOnline,
    this.pendingCount = 0,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppTheme.accentColor : AppTheme.warningColor;

    return InkWell(
      onTap: onSyncTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline
                  ? (pendingCount > 0 ? 'SYNCING ($pendingCount)' : 'ONLINE')
                  : 'OFFLINE ($pendingCount)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
