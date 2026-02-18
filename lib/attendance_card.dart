import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';

class AttendanceCard extends StatelessWidget {
  final DateTime displayedMonth;

  const AttendanceCard({super.key, required this.displayedMonth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Consumer<WorkLog>(
      builder: (context, workLog, child) {
        final percentage = workLog.officeAttendancePercentage(displayedMonth);
        final goalPercentage = themeProvider.attendanceGoal * 100;
        final bool targetMet = percentage >= goalPercentage;

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
              const SizedBox(width: 16),
              Expanded(child: _buildLegend(theme, targetMet, goalPercentage)),
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
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
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

  Widget _buildLegend(ThemeData theme, bool targetMet, double goalPercentage) {
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Define theme-aware colors
    final officeColor = isDarkMode ? const Color(0xFF238636) : const Color(0xFFd1fae5);
    final homeColor = isDarkMode ? const Color(0xFFB94545) : const Color(0xFFfee2e2);
    final leaveColor = isDarkMode ? const Color(0xFFfbbf24) : const Color(0xFFfef3c7);
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  size: 14,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    targetMet ? 'Target Met' : 'Target Not Met',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: targetMet ? theme.colorScheme.primary : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Monthly Goal: ${goalPercentage.toInt()}%',
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildLegendItem(officeColor, 'Office', theme),
              _buildLegendItem(homeColor, 'Home', theme),
              _buildLegendItem(leaveColor, 'Leave', theme),
            ],
          )
        ],
    );
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
