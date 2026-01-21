import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:provider/provider.dart';

class StatusSummary extends StatelessWidget {
  final DateTime displayedMonth;

  const StatusSummary({super.key, required this.displayedMonth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<WorkLog>(
      builder: (context, workLog, child) {
        int officeDays = 0;
        int homeDays = 0;
        int leaveDays = 0;
        int totalWeekdays = 0;

        final daysInMonth = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);

        for (int i = 1; i <= daysInMonth; i++) {
          final day = DateTime(displayedMonth.year, displayedMonth.month, i);
          if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
            totalWeekdays++;
          }
        }

        workLog.log.forEach((date, status) {
          if (date.year == displayedMonth.year && date.month == displayedMonth.month) {
            switch (status) {
              case WorkStatus.office:
                officeDays++;
                break;
              case WorkStatus.home:
                homeDays++;
                break;
              case WorkStatus.leave:
                leaveDays++;
                break;
              case WorkStatus.none:
                break;
            }
          }
        });

        final totalWorkingDays = totalWeekdays - leaveDays;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    theme: theme,
                    icon: Icons.apartment,
                    label: 'OFFICE',
                    value: officeDays.toString(),
                    iconColor: const Color(0xFF10b981),
                    bgColor: const Color(0xFFd1fae5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    theme: theme,
                    icon: Icons.home_work,
                    label: 'HOME',
                    value: homeDays.toString(),
                    iconColor: const Color(0xFFef4444),
                    bgColor: const Color(0xFFfee2e2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    theme: theme,
                    icon: Icons.flight_takeoff,
                    label: 'LEAVE DAYS',
                    value: leaveDays.toString(),
                    iconColor: const Color(0xFFf59e0b),
                    bgColor: const Color(0xFFfef3c7),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    theme: theme,
                    icon: Icons.calendar_today,
                    label: 'WORKING DAYS',
                    value: totalWorkingDays.toString(),
                    iconColor: const Color(0xFF3b82f6),
                    bgColor: const Color(0xFFdbeafe),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
