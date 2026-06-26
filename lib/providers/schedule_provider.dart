import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/schedule_service.dart';

// Provider này nhận vào một String (ngày tháng, VD: '2026-06-25')
// và trả về danh sách lịch trực của ngày hôm đó
final scheduleByDateProvider =
    FutureProvider.family<List<dynamic>, String>((ref, date) async {
  if (date.isEmpty) return [];
  return await ScheduleService.getSchedulesByDate(date);
});
