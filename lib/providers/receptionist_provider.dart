import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../services/api_appointment.dart';

class ReceptionistState {
  final List<Appointment> appointments;
  final List<Appointment> filteredAppointments;
  final bool isLoading;
  final String? errorMessage;
  final DateTime selectedDate;
  final String searchQuery;

  ReceptionistState({
    required this.appointments,
    required this.filteredAppointments,
    required this.isLoading,
    this.errorMessage,
    required this.selectedDate,
    required this.searchQuery,
  });

  ReceptionistState copyWith({
    List<Appointment>? appointments,
    List<Appointment>? filteredAppointments,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    String? searchQuery,
  }) {
    return ReceptionistState(
      appointments: appointments ?? this.appointments,
      filteredAppointments: filteredAppointments ?? this.filteredAppointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Allows setting to null when not provided
      selectedDate: selectedDate ?? this.selectedDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

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
}

final receptionistProvider =
    StateNotifierProvider<ReceptionistQueueNotifier, ReceptionistState>((ref) {
  return ReceptionistQueueNotifier();
});
