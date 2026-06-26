import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clinic_service.dart';
import '../services/api_clinic_service.dart';

final clinicServiceProvider = FutureProvider<List<ClinicService>>((ref) async {
  final List<Map<String, dynamic>> rawList = await ApiClinicService.getServices();
  return rawList.map((e) => ClinicService.fromJson(e)).toList();
});
