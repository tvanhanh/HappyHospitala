
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/api_doctors.dart';
import '../services/api_appointment.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DOCTOR LIST PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Fetches all available doctors for the patient to choose from.
///
/// Returns a [List<Map<String, dynamic>>] where each map contains:
/// `_id`, `name`, `email`, `profile` (with `avatar`, `specialty`,
/// `experience`, `price`, `description`).
///
/// Usage in widget:
/// ```dart
/// final asyncDoctors = ref.watch(doctorListProvider);
/// asyncDoctors.when(data: (list) { ... }, loading: ..., error: ...)
/// ```
final doctorListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DoctorService.getDoctors();
});

// ══════════════════════════════════════════════════════════════════════════════
// DOCTOR DETAIL PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Fetches the full profile of a single doctor by [doctorId].
///
/// Automatically re-fetches when [doctorId] changes (family provider pattern).
/// Returns `null` if the network request fails or doctor is not found.
final doctorDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, doctorId) async {
  return DoctorService.getDoctorById(doctorId);
});

// ══════════════════════════════════════════════════════════════════════════════
// BOOKING STATE
// ══════════════════════════════════════════════════════════════════════════════

/// Represents the current state of the booking form.
///
/// [BUG-10 FIX] — Uses a single [timeSlot] DateTime (ERD canonical format)
/// instead of the old separate [date] + [time] string fields.
class BookingState {
  // ── Form Data ──────────────────────────────────────────────────────────────

  /// The currently selected appointment slot (date + time combined).
  ///
  /// [BUG-10 FIX] Replaces `String date` + `String time` fields.
  /// The backend receives this as: `"timeSlot": "2025-12-31T09:00:00.000Z"`
  /// while still sending `date` and `time` as separate fields for backward
  /// compatibility with the current backend routes.
  final DateTime? timeSlot;

  /// The reason for the medical visit.
  final String reason;

  /// Optional image file selected by the patient (symptom photo).
  final XFile? imageFile;

  /// Cloudinary URL of the uploaded symptom image, after upload completes.
  final String? imageUrl;

  /// Multiple image files picked by the patient.
  final List<XFile> imageFiles;

  /// Multiple Cloudinary URLs after uploading.
  final List<String> imageUrls;

  // ── UI State ───────────────────────────────────────────────────────────────

  /// True while submitting the booking to the backend.
  final bool isSubmitting;

  /// True while uploading the image to Cloudinary.
  final bool isUploadingImage;

  /// Error message to display on failure. Null when no error.
  final String? errorMessage;

  /// True after a successful booking submission.
  final bool isSuccess;

  /// The booking data returned from the API on success (for the success dialog).
  final Map<String, dynamic>? successData;

  /// Hình thức khám: offline hoặc online
  final String appointmentType;

  /// Creates a [BookingState].
  const BookingState({
    this.timeSlot,
    this.reason = '',
    this.imageFile,
    this.imageUrl,
    this.imageFiles = const [],
    this.imageUrls = const [],
    this.isSubmitting = false,
    this.isUploadingImage = false,
    this.errorMessage,
    this.isSuccess = false,
    this.successData,
    this.appointmentType = 'offline',
  });

  /// Initial empty state.
  const BookingState.initial()
      : timeSlot = null,
        reason = '',
        imageFile = null,
        imageUrl = null,
        imageFiles = const [],
        imageUrls = const [],
        isSubmitting = false,
        isUploadingImage = false,
        errorMessage = null,
        isSuccess = false,
        successData = null,
        appointmentType = 'offline';

  /// Creates a copy with optionally updated fields.
  BookingState copyWith({
    DateTime? timeSlot,
    String? reason,
    XFile? imageFile,
    String? imageUrl,
    List<XFile>? imageFiles,
    List<String>? imageUrls,
    bool? isSubmitting,
    bool? isUploadingImage,
    String? errorMessage,
    bool? isSuccess,
    Map<String, dynamic>? successData,
    String? appointmentType,
    bool clearImage = false,
    bool clearError = false,
  }) {
    return BookingState(
      timeSlot: timeSlot ?? this.timeSlot,
      reason: reason ?? this.reason,
      imageFile: clearImage ? null : imageFile ?? this.imageFile,
      imageUrl: clearImage ? null : imageUrl ?? this.imageUrl,
      imageFiles: clearImage ? const [] : imageFiles ?? this.imageFiles,
      imageUrls: clearImage ? const [] : imageUrls ?? this.imageUrls,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      successData: successData ?? this.successData,
      appointmentType: appointmentType ?? this.appointmentType,
    );
  }

  /// True when the user has selected a time slot.
  bool get hasTimeSlot => timeSlot != null;

  /// Returns the date portion formatted as `yyyy-MM-dd` (backend-compatible).
  String get dateString {
    if (timeSlot == null) return '';
    final d = timeSlot!;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Returns the time portion formatted as `HH:mm` (backend-compatible).
  String get timeString {
    if (timeSlot == null) return '';
    final d = timeSlot!;
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  /// Returns the full ISO 8601 representation of [timeSlot].
  /// This is the canonical ERD `timeSlot` field format.
  String get timeSlotIso => timeSlot?.toIso8601String() ?? '';
}

// ══════════════════════════════════════════════════════════════════════════════
// BOOKING NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

/// The global booking state provider.
///
/// Use `.family` with [doctorId] so each doctor's booking form has isolated state.
/// This prevents state leakage when navigating between different BookingScreens.
final bookingProvider =
    StateNotifierProvider.family<BookingNotifier, BookingState, String>(
  (ref, doctorId) => BookingNotifier(ref, doctorId),
);

/// Manages all booking form state and API interactions.
///
/// Key responsibilities:
/// 1. Holds the form state ([BookingState])
/// 2. Validates form before submission
/// 3. Uploads symptom image to Cloudinary
/// 4. Submits booking to backend API
/// 5. Emits Socket.IO event on success ([Booking-3])
class BookingNotifier extends StateNotifier<BookingState> {
  final Ref _ref;
  final String _doctorId;

  BookingNotifier(this._ref, this._doctorId)
      : super(const BookingState.initial()) {
    // _doctorId is reserved for future use (e.g., fetching booked slots).
    assert(_doctorId.isNotEmpty || true);
  }

  // ── Time Slot Selection ────────────────────────────────────────────────────

  /// Updates the selected appointment time slot.
  ///
  /// [BUG-10 FIX] Stores as a unified [DateTime] matching the ERD `timeSlot` field.
  /// The [BookingState.dateString] and [BookingState.timeString] getters
  /// extract the parts for the legacy API format automatically.
  void selectTimeSlot(DateTime slot) {
    state = state.copyWith(timeSlot: slot, clearError: true);
  }

  /// Clears the currently selected time slot.
  void clearTimeSlot() {
    state = state.copyWith(timeSlot: null);
  }

  // ── Form Fields ────────────────────────────────────────────────────────────

  /// Updates the visit reason field.
  void setReason(String value) {
    state = state.copyWith(reason: value, clearError: true);
  }

  /// Updates the appointment consultation type.
  void setAppointmentType(String value) {
    state = state.copyWith(appointmentType: value, clearError: true);
  }

  /// Picks multiple images from gallery and uploads them to Cloudinary.
  ///
  /// Shows a loading state during upload via [BookingState.isUploadingImage].
  /// Stores Cloudinary URLs in [BookingState.imageUrls] on success.
  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final List<XFile> pickedList = await picker.pickMultiImage(
      imageQuality: 80, // Compress to reduce upload time
    );

    if (pickedList.isEmpty) return;

    final updatedFiles = List<XFile>.from(state.imageFiles)..addAll(pickedList);
    state = state.copyWith(imageFiles: updatedFiles, isUploadingImage: true);

    try {
      final List<String> uploadedUrls = [];
      for (final file in pickedList) {
        final url = await _uploadToCloudinary(file);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
      final updatedUrls = List<String>.from(state.imageUrls)
        ..addAll(uploadedUrls);
      final combinedUrls = updatedUrls.isEmpty ? null : updatedUrls.join(',');

      state = state.copyWith(
        imageUrls: updatedUrls,
        imageUrl: combinedUrls, // For backward compatibility
        isUploadingImage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUploadingImage: false,
        errorMessage: 'Tải ảnh thất bại: $e',
      );
    }
  }

  /// Removes a selected image at a specific index.
  void removeImageAtIndex(int index) {
    if (index < 0 || index >= state.imageUrls.length) return;
    final updatedUrls = List<String>.from(state.imageUrls)..removeAt(index);
    final List<XFile> updatedFiles = List<XFile>.from(state.imageFiles);
    if (index < updatedFiles.length) {
      updatedFiles.removeAt(index);
    }
    final combinedUrls = updatedUrls.isEmpty ? null : updatedUrls.join(',');

    state = state.copyWith(
      imageUrls: updatedUrls,
      imageFiles: updatedFiles,
      imageUrl: combinedUrls,
      clearImage: updatedUrls.isEmpty,
    );
  }

  /// Removes all selected images.
  void removeImage() {
    state = state.copyWith(clearImage: true);
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  /// Validates the form before submission.
  /// Returns an error message string if invalid, null if valid.
  String? _validate() {
    if (state.reason.trim().isEmpty) {
      return 'Vui lòng nhập lý do khám.';
    }
    if (!state.hasTimeSlot) {
      return 'Vui lòng chọn ngày và giờ khám.';
    }
    // Ensure the selected slot is in the future
    if (state.timeSlot!.isBefore(DateTime.now())) {
      return 'Thời gian đặt lịch phải là trong tương lai.';
    }
    return null;
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  /// Validates and submits the booking to the backend.
  ///
  /// [RACE CONDITION GUARD] — Performs a pre-check BEFORE submit to catch
  /// slot conflicts early. The backend also has a compound unique index
  /// as a final safety net against simultaneous requests.
  Future<void> submitBooking({
    required String doctorId,
    required String specialtyId,
    required String patientName,
    required String phone,
    required String gender,
    required String address,
    required String medicalHistory,
    required String allergies,
    required String cccd,
    required String birthDate,
    required String paymentMethod,
  }) async {
    // [STEP 1] Local validation
    final validationError = _validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // [STEP 2] Pre-check slot availability before submitting
      // Giúp bắt conflict sớm và hiển thị thông báo rõ ràng cho user
      final slotCheck = await AppointmentApi.checkSlotAvailability(
        doctorId: doctorId,
        date: state.dateString,
        time: state.timeString,
      );

      if (slotCheck['available'] == false) {
        // Slot vừa bị người khác đặt — invalidate cache để UI cập nhật
        _ref.invalidate(bookedSlotsProvider((
          doctorId: doctorId,
          date: state.dateString,
        )));
        state = state.copyWith(
          isSubmitting: false,
          // Clear selected slot so user picks a new one
          timeSlot: null,
          errorMessage:
              '⚠️ Ca khám ${state.timeString} ngày ${state.dateString} vừa được người khác đặt. Vui lòng chọn giờ khác.',
        );
        return;
      }

      // [STEP 3] Submit booking
      final result = await AppointmentApi.addAppointment(
        doctorId: doctorId,
        specialtyId: specialtyId,
        patientName: patientName,
        phone: phone,
        cccd: cccd,
        birthDate: birthDate,
        gender: gender,
        address: address,
        medicalHistory: medicalHistory,
        allergies: allergies,
        reason: state.reason.trim(),
        date: state.dateString,
        time: state.timeString,
        timeSlot: state.timeSlotIso,
        imageUrl: state.imageUrl,
        paymentMethod: paymentMethod,
        appointmentType: state.appointmentType,
      );

      final isOk = result['success'] == true;

      if (isOk) {
        // [Booking-3] Emit real-time socket event so Receptionist dashboard
        // receives instant notification without polling.
        _emitNewAppointmentEvent(
          appointmentData: result['data'] as Map<String, dynamic>? ?? {},
          doctorId: doctorId,
          patientName: patientName,
          timeSlot: state.timeSlotIso,
          reason: state.reason,
        );

        // Invalidate booked slots cache so the grid refreshes immediately
        _ref.invalidate(bookedSlotsProvider((
          doctorId: doctorId,
          date: state.dateString,
        )));

        state = state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          successData: result['data'] as Map<String, dynamic>?,
        );
      } else {
        // Handle slot conflict response from server (409)
        final isSlotConflict = result['slotConflict'] == true;
        if (isSlotConflict) {
          _ref.invalidate(bookedSlotsProvider((
            doctorId: doctorId,
            date: state.dateString,
          )));
        }
        state = state.copyWith(
          isSubmitting: false,
          timeSlot: isSlotConflict ? null : state.timeSlot,
          errorMessage:
              result['message']?.toString() ?? 'Đặt lịch thất bại. Thử lại.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Resets the booking state to allow re-booking.
  void reset() {
    state = const BookingState.initial();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// [Booking-3] Emits [SocketEvents.newAppointment] to notify staff dashboards.
  ///
  /// Includes enough data for the Receptionist to display a meaningful
  /// notification without a separate API call.
  void _emitNewAppointmentEvent({
    required Map<String, dynamic> appointmentData,
    required String doctorId,
    required String patientName,
    required String timeSlot,
    required String reason,
  }) {
    final authState = _ref.read(authProvider);
    SocketService.instance.emit(SocketEvents.newAppointment, {
      'appointmentId': appointmentData['_id']?.toString() ?? '',
      'patientName': patientName,
      'patientId': authState.userId ?? '',
      'doctorId': doctorId,
      // [BUG-10 FIX] Use the unified ERD timeSlot ISO string
      'timeSlot': timeSlot,
      'reason': reason,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Uploads [imageFile] to Cloudinary and returns the secure URL.
  Future<String?> _uploadToCloudinary(XFile file) async {
    const cloudName = 'dwlikpvh9';
    const uploadPreset = 'asset_clinic';

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(resBody)['secure_url'] as String?;
    }
    throw Exception('Cloudinary error ${response.statusCode}: $resBody');
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AVAILABLE TIME SLOTS
// ══════════════════════════════════════════════════════════════════════════════

/// Returns the list of available clinic time slots for a given [date]
/// based on the doctor's assigned schedule for that day.
/// Filters out slots that are in the past when [date] is today.
/// [Booking-4] — Used by the time slot grid/chip selector in the UI.
List<DateTime> getAvailableSlots(DateTime date, List<String> bookedSlots, List<dynamic> schedules) {
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;

  // Lấy tất cả lịch của bác sĩ trong ngày `date`
  final daySchedules = schedules.where((s) {
    if (s == null || s['date'] == null) return false;
    final d = DateTime.parse(s['date']).toLocal();
    return d.year == date.year && d.month == date.month && d.day == date.day;
  }).toList();

  if (daySchedules.isEmpty) return []; // No schedule for this date!

  List<DateTime> allSlots = [];

  for (final sched in daySchedules) {
    final shift = sched['shift']?.toString() ?? 'Cả ngày';
    final duration = sched['timeSlotDuration'] != null ? (sched['timeSlotDuration'] as num).toInt() : 15;

    void generateSlots(int startHour, int startMinute, int endHour, int endMinute) {
      var current = DateTime(date.year, date.month, date.day, startHour, startMinute);
      final end = DateTime(date.year, date.month, date.day, endHour, endMinute);
      
      while (current.isBefore(end)) {
        if (!allSlots.any((s) => s.isAtSameMomentAs(current))) {
          allSlots.add(current);
        }
        current = current.add(Duration(minutes: duration));
      }
    }

    if (shift == 'Sáng' || shift == 'Cả ngày') {
      generateSlots(7, 30, 11, 30);
    }
    if (shift == 'Chiều' || shift == 'Cả ngày') {
      generateSlots(13, 30, 17, 30);
    }
    if (shift == 'Tối' || shift == 'Cả ngày') {
      generateSlots(17, 0, 20, 0);
    }
  }

  // Sort slots chronologically
  allSlots.sort((a, b) => a.compareTo(b));

  return allSlots.where((slot) {
    if (isToday && !slot.isAfter(now)) return false;
    final timeStr =
        '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
    return !bookedSlots.contains(timeStr);
  }).toList();
}

/// Fetches booked slots for a specific doctor on a specific date.
final bookedSlotsProvider =
    FutureProvider.autoDispose.family<List<String>, ({String doctorId, String date})>(
        (ref, args) async {
  return AppointmentApi.getBookedSlots(
      doctorId: args.doctorId, date: args.date);
});

/// Fetches the assigned schedules for a specific doctor.
final doctorScheduleListProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, doctorId) async {
  return AppointmentApi.getDoctorSchedules(doctorId);
});
