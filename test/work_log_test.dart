
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WorkLogStorage', () {
    test('should write and read a work log correctly', () async {
      final initialLog = {
        DateTime(2024, 7, 21): WorkStatus.office,
        DateTime(2024, 7, 22): WorkStatus.home,
      };

      await WorkLogStorage.writeWorkLog(initialLog);
      final readLog = await WorkLogStorage.readWorkLog();

      expect(readLog.length, 2);
      expect(readLog[DateTime(2024, 7, 21)], WorkStatus.office);
      expect(readLog[DateTime(2024, 7, 22)], WorkStatus.home);
    });

    test('reading from an empty storage should return an empty map', () async {
      final readLog = await WorkLogStorage.readWorkLog();

      expect(readLog, isEmpty);
    });
  });

  group('WorkLog Class (UI Flow)', () {
    test('updateStatus should save the log using WorkLogStorage', () async {
      final workLog = WorkLog();
      final testDate = DateTime(2024, 7, 23);
      
      await workLog.updateStatus(testDate, WorkStatus.leave);
      
      final storedLog = await WorkLogStorage.readWorkLog();
      expect(storedLog[testDate], WorkStatus.leave);
    });

    test('loadLog should load data from WorkLogStorage', () async {
      final testDate = DateTime(2024, 7, 24);
      await WorkLogStorage.writeWorkLog({testDate: WorkStatus.office});
      final workLog = WorkLog();

      await workLog.loadLog();

      expect(workLog.getStatus(testDate), WorkStatus.office);
    });
  });

  group('Background Notification Flow', () {
    test('updateStatusInBackground should correctly update the status', () async {
      final yesterday = DateUtils.dateOnly(DateTime.now()).subtract(const Duration(days: 1));
      await WorkLogStorage.writeWorkLog({yesterday: WorkStatus.home});

      await updateStatusInBackground(WorkStatus.office);

      final storedLog = await WorkLogStorage.readWorkLog();
      final today = DateUtils.dateOnly(DateTime.now());

      expect(storedLog.length, 2);
      expect(storedLog[today], WorkStatus.office);
      expect(storedLog[yesterday], WorkStatus.home);
    });
  });
}
