import 'package:flutter/material.dart';

class SchedulingHelper {
  // ==========================================
  // RULE 1: THE 7:30 AM RESCHEDULE LOCKOUT
  // ==========================================
  static bool canRescheduleToday(DateTime inspectionDate) {
    final now = DateTime.now();

    // Check if the inspection is scheduled for today
    if (now.year == inspectionDate.year &&
        now.month == inspectionDate.month &&
        now.day == inspectionDate.day) {
      // If it's today, is it past 7:30 AM?
      if (now.hour > 7 || (now.hour == 7 && now.minute >= 30)) {
        return false; // Locked!
      }
    }
    return true; // Safe to reschedule
  }

  // ==========================================
  // RULES 2, 3, 4: THE 3:00 PM CUTOFF LOGIC
  // ==========================================

  /// Returns the absolute earliest day a user is allowed to pick on the calendar
  static DateTime getFirstAvailableDate(List<DateTime> holidays) {
    final now = DateTime.now();

    // 1. Is it past 3:00 PM (15:00)?
    final isPastCutoff = now.hour >= 15;

    // 2. Find the immediate next business day
    DateTime nextBusinessDay = _getNextBusinessDay(now, holidays);

    if (isPastCutoff) {
      // If past 3 PM, that immediate next business day is BLOCKED.
      // We must push the first available date out one more business day.
      return _getNextBusinessDay(nextBusinessDay, holidays);
    } else {
      // If before 3 PM, they can schedule for the very next business day.
      return nextBusinessDay;
    }
  }

  /// Evaluates if a specific day on the calendar should be clickable
  static bool isDaySelectable(
    DateTime day,
    DateTime firstAvailable,
    List<DateTime> holidays,
  ) {
    // 1. Block Weekends
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return false;
    }

    // 2. Block Holidays
    if (_isHoliday(day, holidays)) {
      return false;
    }

    // 3. Block any days before our calculated "First Available" date
    // (We zero out the times to ensure clean date-to-date comparison)
    final compareDay = DateTime(day.year, day.month, day.day);
    final compareFirst = DateTime(
      firstAvailable.year,
      firstAvailable.month,
      firstAvailable.day,
    );

    if (compareDay.isBefore(compareFirst)) {
      return false;
    }

    return true; // The day passed all rules and is clickable!
  }

  // --- PRIVATE HELPERS ---

  static DateTime _getNextBusinessDay(DateTime start, List<DateTime> holidays) {
    DateTime next = start.add(const Duration(days: 1));

    // Keep adding a day as long as we land on a weekend or a holiday
    while (next.weekday == DateTime.saturday ||
        next.weekday == DateTime.sunday ||
        _isHoliday(next, holidays)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static bool _isHoliday(DateTime date, List<DateTime> holidays) {
    // Check if the date matches any date in our holidays list
    return holidays.any(
      (h) => h.year == date.year && h.month == date.month && h.day == date.day,
    );
  }
}
