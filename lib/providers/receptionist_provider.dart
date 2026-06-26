import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../services/api_appointment.dart';

// ─── MODEL: Triage Handoff Item ─────────────────────────────────────────────
class TriageHandoff {
  final String patientId;
  final String patientName;
  final String patientAvatar;
  final String patientPhone;
  final String patientGender;
  final String patientDOB;
  final String symptomsPreview;
  final DateTime updatedAt;

  TriageHandoff({
    required this.patientId,
    required this.patientName,
    required this.patientAvatar,
    required this.patientPhone,
    required this.patientGender,
    required this.patientDOB,
    required this.symptomsPreview,
    required this.updatedAt,
  });

  factory TriageHandoff.fromJson(Map<String, dynamic> json) {
    return TriageHandoff(
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Bệnh nhân ẩn danh',
      patientAvatar: json['patientAvatar']?.toString() ?? '',
      patientPhone: json['patientPhone']?.toString() ?? 'Chưa cập nhật',
      patientGender: json['patientGender']?.toString() ?? 'Không rõ',
      patientDOB: json['patientDOB']?.toString() ?? 'Chưa rõ',
      symptomsPreview: json['symptomsPreview']?.toString() ?? 'Cần hỗ trợ',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ─── STATE ──────────────────────────────────────────────────────────────────
class ReceptionistState {
  final List<Appointment> appointments;
  final List<Appointment> filteredAppointments;
  final bool isLoading;
  final String? errorMessage;
  final DateTime selectedDate;
  final String searchQuery;
  // Handoff state
  final List<TriageHandoff> triageHandoffs;
  final bool isHandoffLoading;

  ReceptionistState({
    required this.appointments,
    required this.filteredAppointments,
    required this.isLoading,
    this.errorMessage,
    required this.selectedDate,
    required this.searchQuery,
    this.triageHandoffs = const [],
    this.isHandoffLoading = false,
  });

  ReceptionistState copyWith({
    List<Appointment>? appointments,
    List<Appointment>? filteredAppointments,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    String? searchQuery,
    List<TriageHandoff>? triageHandoffs,
    bool? isHandoffLoading,
  }) {
    return ReceptionistState(
      appointments: appointments ?? this.appointments,
      filteredAppointments: filteredAppointments ?? this.filteredAppointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Allows setting to null when not provided
      selectedDate: selectedDate ?? this.selectedDate,
      searchQuery: searchQuery ?? this.searchQuery,
      triageHandoffs: triageHandoffs ?? this.triageHandoffs,
      isHandoffLoading: isHandoffLoading ?? this.isHandoffLoading,
    );
  }
}

// ─── NOTIFIER ───────────────────────────────────────────────────────────────
class ReceptionistQueueNotifier extends StateNotifier<ReceptionistState> {
  ReceptionistQueueNotifier()
      : super(ReceptionistState(
          appointments: [],
          filteredAppointments: [],
          isLoading: false,
          selectedDate: DateTime.now(),
          searchQuery: '',
        ));

  Future<void> fetchAppointments(DateTime date) async {
    state = state.copyWith(isLoading: true, errorMessage: null, selectedDate: date);
    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final rawData = await AppointmentApi.getAppointmentsByDate(dateStr);
      final List<Appointment> fetched = rawData.map((e) => Appointment.fromJson(e)).toList();

      state = state.copyWith(
        appointments: fetched,
        isLoading: false,
      );
      // Re-apply search filter
      search(state.searchQuery);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Lỗi tải danh sách lịch hẹn: $e",
      );
    }
  }

  void search(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      state = state.copyWith(
        searchQuery: query,
        filteredAppointments: state.appointments,
      );
    } else {
      final filtered = state.appointments.where((appointment) {
        final matchesName = appointment.patientName.toLowerCase().contains(cleanQuery);
        final matchesCccd = appointment.cccd.toLowerCase().contains(cleanQuery);
        final matchesId = appointment.id.toLowerCase().contains(cleanQuery);
        return matchesName || matchesCccd || matchesId;
      }).toList();

      state = state.copyWith(
        searchQuery: query,
        filteredAppointments: filtered,
      );
    }
  }

  Future<bool> checkInPatient(String appointmentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await AppointmentApi.checkInAppointment(appointmentId);
      if (success) {
        // Map local list in-place to update the target status to 'checked_in'
        final updatedAppointments = state.appointments.map((appt) {
          if (appt.id == appointmentId) {
            return appt.copyWith(status: 'checked_in');
          }
          return appt;
        }).toList();

        state = state.copyWith(
          appointments: updatedAppointments,
          isLoading: false,
        );
        // Re-apply filter to refresh filteredAppointments
        search(state.searchQuery);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Check-in thất bại từ server.",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Lỗi check-in: $e",
      );
      return false;
    }
  }

  // ─── TRIAGE HANDOFF MANAGEMENT ─────────────────────────────────────────────
  Future<void> fetchTriageHandoffs() async {
    state = state.copyWith(isHandoffLoading: true);
    try {
      final rawData = await AppointmentApi.getTriageHandoffs();
      final List<TriageHandoff> handoffs =
          rawData.map((e) => TriageHandoff.fromJson(e as Map<String, dynamic>)).toList();

      state = state.copyWith(
        triageHandoffs: handoffs,
        isHandoffLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isHandoffLoading: false,
        errorMessage: "Lỗi tải danh sách bàn giao: $e",
      );
    }
  }

  Future<bool> acceptHandoffChat(String patientId) async {
    try {
      final result = await AppointmentApi.initiateHandoffChat(patientId);
      if (result['success'] == true) {
        // Remove accepted handoff from local list
        final updated = state.triageHandoffs
            .where((h) => h.patientId != patientId)
            .toList();
        state = state.copyWith(triageHandoffs: updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: "Lỗi tiếp nhận cuộc trò chuyện: $e",
      );
      return false;
    }
  }

  // ─── CONFIRM STATUS (XÁC NHẬN LỊCH HẸN: pending → confirmed) ──────────────
  Future<bool> confirmAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await AppointmentApi.updateStatus(
        id: appointmentId,
        status: 'confirmed',
      );
      if (result['success'] == true) {
        final updatedAppointments = state.appointments.map((appt) {
          if (appt.id == appointmentId) {
            return appt.copyWith(status: 'confirmed');
          }
          return appt;
        }).toList();

        state = state.copyWith(
          appointments: updatedAppointments,
          isLoading: false,
        );
        search(state.searchQuery);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? "Xác nhận thất bại.",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Lỗi xác nhận: $e",
      );
      return false;
    }
  }
}

final receptionistProvider =
    StateNotifierProvider<ReceptionistQueueNotifier, ReceptionistState>((ref) {
  return ReceptionistQueueNotifier();
});
