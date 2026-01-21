import 'package:flutter/material.dart';
import 'package:myapp/main.dart'; 
import 'package:provider/provider.dart';

class AttendanceCard extends StatelessWidget {
  final DateTime displayedMonth;

  const AttendanceCard({super.key, required this.displayedMonth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<WorkLog>(
      builder: (context, workLog, child) {
        final percentage = workLog.officeAttendancePercentage(displayedMonth);
        final bool targetMet = percentage >= 60;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              _buildProgressIndicator(theme, percentage),
              const SizedBox(width: 24),
              _buildLegend(theme, targetMet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, double percentage) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'IN OFFICE',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, bool targetMet) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: targetMet ? const Color(0xFFd1fae5) : const Color(0xFFfee2e2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  targetMet ? Icons.check_circle : Icons.cancel,
                  color: targetMet ? theme.colorScheme.primary : theme.colorScheme.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  targetMet ? 'Target Met' : 'Target Not Met',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: targetMet ? theme.colorScheme.primary : theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Monthly Goal: 60%',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem(const Color(0xFFd1fae5), 'Office', theme),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFfee2e2), 'Home', theme),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFfef3c7), 'Leave', theme),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
