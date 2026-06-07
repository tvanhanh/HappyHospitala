/// Patient Appointment Booking Screen — fully refactored with Riverpod.
///
/// Refactoring summary:
/// - [Booking-1] All async state (doctor detail, form, submission) managed by
///   Riverpod providers: [doctorDetailProvider] and [bookingProvider].
///   Legacy setState calls have been removed.
/// - [Booking-2] [BUG-10 FIX] TimeSlot uses a single [DateTime] (ERD-compliant)
///   instead of separate date + time strings.
/// - [Booking-3] Emits [SocketEvents.newAppointment] on success via [SocketService].
/// - [Booking-4] UI upgraded: time slot grid with styled chips, success dialog,
///   image upload status indicator, proper error snackbar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1565C0);
const Color _kBackground = Color(0xFFF4F6FA);
const Color _kSurface = Colors.white;
const Color _kSuccess = Color(0xFF2E7D32);

String _formatEmergencyContactString(String raw) {
  if (raw.isEmpty) return '';
  String cleaned = raw.trim();
  if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
    final nameReg = RegExp(r'(?:name|\"name\")\s*[:=]\s*([^,}]+)');
    final phoneReg = RegExp(r'(?:phone|\"phone\")\s*[:=]\s*([^,}]+)');

    final nameMatch = nameReg.firstMatch(cleaned);
    final phoneMatch = phoneReg.firstMatch(cleaned);

    String nameVal = nameMatch?.group(1)?.trim() ?? '';
    String phoneVal = phoneMatch?.group(1)?.trim() ?? '';

    if (nameVal.startsWith('"') || nameVal.startsWith("'")) {
      nameVal = nameVal.substring(1);
    }
    if (nameVal.endsWith('"') || nameVal.endsWith("'")) {
      nameVal = nameVal.substring(0, nameVal.length - 1);
    }

    if (phoneVal.startsWith('"') || phoneVal.startsWith("'")) {
      phoneVal = phoneVal.substring(1);
    }
    if (phoneVal.endsWith('"') || phoneVal.endsWith("'")) {
      phoneVal = phoneVal.substring(0, phoneVal.length - 1);
    }

    if (nameVal.isNotEmpty && phoneVal.isNotEmpty) {
      return '$nameVal - $phoneVal';
    } else if (nameVal.isNotEmpty) {
      return nameVal;
    } else if (phoneVal.isNotEmpty) {
      return phoneVal;
    }
  }
  return cleaned;
}

/// The appointment booking screen, refactored with Riverpod.
///
/// Accepts [doctorId] as a required path parameter from the GoRouter route:
/// `/booking/:doctorId`
///
/// Uses [bookingProvider].family([doctorId]) for isolated state per booking.
class BookingScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const BookingScreen({super.key, required this.doctorId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profile fields — loaded once from API in initState and kept locally
  // since they are read-only in the booking form.
  String _patientName = '';
  String _phone = '';
  String _gender = '';
  String _address = '';
  String _medicalHistory = '';
  String _allergies = '';
  String _dateOfBirth = '';
  String _bloodType = '';
  String _chronicDiseases = '';
  String _emergencyContact = '';
  String _identityCard = '';
  bool _profileLoaded = false;
  String _selectedPaymentMethod = 'cash';

  // Date selection (controls which day's slots are shown in the grid)
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  /// Loads the patient's profile once to pre-fill the form.
  /// Does NOT use setState for the booking state — only for local profile fields.
  Future<void> _loadPatientProfile() async {
    try {
      final res = await ApiService.getProfile();
      final p = (res['profile'] as Map<String, dynamic>?) ?? {};
      final auth = ref.read(authProvider);

      final rawEmergency = p['emergencyContact'];
      String formattedEmergency = '';
      if (rawEmergency is Map) {
        final eName = rawEmergency['name']?.toString() ?? '';
        final ePhone = rawEmergency['phone']?.toString() ?? '';
        if (eName.isNotEmpty && ePhone.isNotEmpty) {
          formattedEmergency = '$eName - $ePhone';
        } else if (eName.isNotEmpty) {
          formattedEmergency = eName;
        } else if (ePhone.isNotEmpty) {
          formattedEmergency = ePhone;
        }
      } else if (rawEmergency is String) {
        formattedEmergency = _formatEmergencyContactString(rawEmergency);
      }

      if (mounted) {
        setState(() {
          _patientName = auth.name ?? '';
          _phone = p['phone']?.toString() ?? '';
          _gender = p['gender']?.toString() ?? '';
          _address = p['address']?.toString() ?? '';
          _medicalHistory = p['medicalHistory']?.toString() ?? '';
          _allergies = p['allergies']?.toString() ?? '';
          _dateOfBirth = p['dateOfBirth']?.toString() ?? '';
          _bloodType = p['bloodType']?.toString() ?? '';
          _chronicDiseases = p['chronicDiseases']?.toString() ?? '';
          _emergencyContact = formattedEmergency;
          _identityCard =
              p['identityCard']?.toString() ?? p['cccd']?.toString() ?? '';
          _profileLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _profileLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the booking state for this specific doctor
    final bookingState = ref.watch(bookingProvider(widget.doctorId));

    // Watch doctor detail (async)
    final asyncDoctor = ref.watch(doctorDetailProvider(widget.doctorId));

    // [Booking-3] Listen for success to show dialog
    ref.listen<BookingState>(bookingProvider(widget.doctorId), (prev, next) {
      if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        _showSuccessDialog(next);
      }
      // Show error snackbar
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Đặt Lịch Khám'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncDoctor.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _kPrimary),
              SizedBox(height: 16),
              Text('Đang tải thông tin bác sĩ...',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Không thể tải thông tin bác sĩ',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                onPressed: () =>
                    ref.refresh(doctorDetailProvider(widget.doctorId)),
              ),
            ],
          ),
        ),
        data: (doctor) {
          if (doctor == null) {
            return const Center(child: Text('Không tìm thấy bác sĩ.'));
          }
          return _buildBody(context, doctor, bookingState);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAIN BODY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBody(
    BuildContext context,
    Map<String, dynamic> doctor,
    BookingState bookingState,
  ) {
    String clinicRoom = '';
    if (doctor['roomId'] != null) {
      if (doctor['roomId'] is Map) {
        final roomNum = doctor['roomId']['roomNumber']?.toString() ?? '';
        final roomFloor = doctor['roomId']['floor']?.toString() ?? '';
        if (roomNum.isNotEmpty) {
          clinicRoom = roomFloor.isNotEmpty
              ? 'Phòng $roomNum (Tầng $roomFloor)'
              : 'Phòng $roomNum';
        }
      }
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Doctor Summary Card ────────────────────────────────────────
            _DoctorSummaryCard(doctor: doctor),
            const SizedBox(height: 20),

            // ── Patient Info Card (read-only with edit capability) ─────────
            _PatientInfoCard(
              name: _patientName,
              phone: _phone,
              gender: _gender,
              address: _address,
              medicalHistory: _medicalHistory,
              allergies: _allergies,
              dateOfBirth: _dateOfBirth,
              bloodType: _bloodType,
              chronicDiseases: _chronicDiseases,
              emergencyContact: _emergencyContact,
              identityCard: _identityCard,
              clinicRoom: clinicRoom,
              isLoaded: _profileLoaded,
              onEdit: _showEditProfileDialog,
            ),
            const SizedBox(height: 20),

            // ── Visit Reason Field ─────────────────────────────────────────
            _SectionLabel(
              icon: Icons.note_alt_outlined,
              label: 'Lý do khám *',
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: _inputDeco(
                hint: 'Mô tả triệu chứng, lý do bạn muốn khám...',
              ),
              onChanged: (v) => ref
                  .read(bookingProvider(widget.doctorId).notifier)
                  .setReason(v),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập lý do'
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Image Upload ───────────────────────────────────────────────
            _ImageUploadSection(doctorId: widget.doctorId),
            const SizedBox(height: 20),

            // ── Date Picker ────────────────────────────────────────────────
            _SectionLabel(
              icon: Icons.calendar_today_rounded,
              label: 'Chọn ngày *',
            ),
            const SizedBox(height: 10),
            _DatePickerRow(
              selectedDate: _selectedDate,
              onDateSelected: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 20),

            // ── [Booking-4] Time Slot Grid (Chip-based) ────────────────────
            _SectionLabel(
              icon: Icons.access_time_rounded,
              label: 'Chọn giờ khám *',
            ),
            const SizedBox(height: 10),
            _TimeSlotGrid(
              selectedDate: _selectedDate,
              doctorId: widget.doctorId,
            ),
            const SizedBox(height: 28),

            // ── Payment Method Selector ────────────────────────────────────
            _SectionLabel(
              icon: Icons.payment_rounded,
              label: 'Phương thức thanh toán *',
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.3,
              children: [
                _buildPaymentMethodOption('cash', 'Tiền mặt', Icons.payments_rounded),
                _buildPaymentMethodOption('banking', 'Chuyển khoản', Icons.account_balance_rounded),
                _buildPaymentMethodOption('vnpay', 'Cổng VNPAY', Icons.credit_card_rounded),
                _buildPaymentMethodOption('momo', 'Ví MoMo', Icons.wallet_rounded),
              ],
            ),
            const SizedBox(height: 28),

            // ── Clinic Address & Map section ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded,
                          color: _kPrimary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Phòng khám Happy Clinic',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '317 Trần Đại Nghĩa, Đà Nẵng',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=317+Tran+Dai+Nghia+Da+Nang');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text(
                        'Xem Google Map',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── Submit Button ──────────────────────────────────────────────
            _SubmitButton(
              formKey: _formKey,
              doctorId: widget.doctorId,
              doctor: doctor,
              patientName: _patientName,
              phone: _phone,
              gender: _gender,
              address: _address,
              medicalHistory: _medicalHistory,
              allergies: _allergies,
              dateOfBirth: _dateOfBirth,
              bloodType: _bloodType,
              chronicDiseases: _chronicDiseases,
              emergencyContact: _emergencyContact,
              identityCard: _identityCard,
              paymentMethod: _selectedPaymentMethod,
              isSubmitting: bookingState.isSubmitting,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue.shade900 : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════════════════════════════════════════

  /// [Booking-4] Beautiful success confirmation dialog shown after booking.
  void _showSuccessDialog(BookingState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated check icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _kSuccess.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _kSuccess,
                  size: 52,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đặt lịch thành công! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kSuccess,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Show selected time slot ([BUG-10] ERD format)
              if (state.timeSlot != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kPrimary.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      _SuccessInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Ngày',
                        value: DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                            .format(state.timeSlot!),
                      ),
                      const Divider(height: 16),
                      _SuccessInfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Giờ',
                        value: DateFormat('HH:mm').format(state.timeSlot!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Hệ thống đã ghi nhận lịch hẹn của bạn.\nLễ tân sẽ xác nhận sớm nhất có thể.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Reset provider state and navigate back
                    ref.read(bookingProvider(widget.doctorId).notifier).reset();
                    context.go('/patient/appointments');
                  },
                  child: const Text(
                    'Xem lịch hẹn của tôi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(bookingProvider(widget.doctorId).notifier).reset();
                  context.pop();
                },
                child: Text('Quay lại',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _patientName);
    final phoneCtrl = TextEditingController(text: _phone);
    final dobCtrl = TextEditingController(text: _dateOfBirth);
    final genderCtrl = TextEditingController(text: _gender);
    final bloodCtrl = TextEditingController(text: _bloodType);
    final addrCtrl = TextEditingController(text: _address);
    final emergencyCtrl = TextEditingController(text: _emergencyContact);
    final chronicCtrl = TextEditingController(text: _chronicDiseases);
    final histCtrl = TextEditingController(text: _medicalHistory);
    final allergyCtrl = TextEditingController(text: _allergies);
    final cccdCtrl = TextEditingController(text: _identityCard);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật Hồ sơ'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _dialogField('Họ và tên', nameCtrl, Icons.person_outlined),
              _dialogField('Số CCCD *', cccdCtrl, Icons.badge_outlined),
              _dialogField(
                  'Ngày sinh (YYYY-MM-DD) *', dobCtrl, Icons.cake_outlined),
              _dialogField('Giới tính', genderCtrl, Icons.wc_outlined),
              _dialogField('Nhóm máu', bloodCtrl, Icons.bloodtype_outlined),
              _dialogField('Số điện thoại', phoneCtrl, Icons.phone_outlined),
              _dialogField('Liên hệ khẩn cấp (Tên - SĐT)', emergencyCtrl,
                  Icons.contact_emergency_outlined),
              _dialogField('Địa chỉ', addrCtrl, Icons.location_on_outlined),
              _dialogField('Bệnh nền (VD: Tiểu đường...)', chronicCtrl,
                  Icons.coronavirus_outlined,
                  maxLines: 2),
              _dialogField('Tiền sử bệnh', histCtrl, Icons.history_outlined,
                  maxLines: 2),
              _dialogField('Dị ứng', allergyCtrl, Icons.warning_amber_outlined,
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _patientName = nameCtrl.text;
                _phone = phoneCtrl.text;
                _dateOfBirth = dobCtrl.text;
                _gender = genderCtrl.text;
                _bloodType = bloodCtrl.text;
                _address = addrCtrl.text;
                _emergencyContact = emergencyCtrl.text;
                _chronicDiseases = chronicCtrl.text;
                _medicalHistory = histCtrl.text;
                _allergies = allergyCtrl.text;
                _identityCard = cccdCtrl.text;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: _kPrimary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

/// Section label with an icon — used above each form section.
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kPrimary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
      ],
    );
  }
}

/// Card showing the selected doctor's key info at the top.
class _DoctorSummaryCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorSummaryCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final bool isNewFormat =
        doctor.containsKey('userId') && doctor['userId'] is Map;
    final Map<String, dynamic> userMap =
        isNewFormat ? (doctor['userId'] as Map<String, dynamic>) : doctor;

    final String name = userMap['fullName'] ?? userMap['name'] ?? 'Bác sĩ';
    final String avatar = userMap['avatar'] ?? '';

    // Specialty Name
    String specialtyName = doctor['specialty']?.toString() ?? '';
    if (specialtyName.isEmpty && doctor['departmentId'] != null) {
      if (doctor['departmentId'] is Map) {
        specialtyName = doctor['departmentId']['name']?.toString() ?? '';
      }
    }
    if (specialtyName.isEmpty) {
      specialtyName = 'Chuyên khoa';
    }

    // Experience
    final dynamic expYears =
        doctor['experience_years'] ?? doctor['experience'] ?? 0;

    // Price
    final dynamic priceRaw = doctor['consultationFee'] ?? doctor['price'] ?? 0;
    double parsedPrice = 0.0;
    if (priceRaw is num) {
      parsedPrice = priceRaw.toDouble();
    } else if (priceRaw is String) {
      parsedPrice =
          double.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    final price =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(parsedPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Doctor Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                  width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: avatar.isNotEmpty
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        child: const Icon(Icons.person,
                            color: Color(0xFF1565C0), size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      child: const Icon(Icons.person,
                          color: Color(0xFF1565C0), size: 36),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    specialtyName,
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (expYears != null && expYears != 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_outlined,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '$expYears năm kinh nghiệm',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Consultation Fee / Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Giá khám',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                      width: 1),
                ),
                child: Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Patient info card with an edit button.
class _PatientInfoCard extends StatelessWidget {
  final String name, phone, gender, address, medicalHistory, allergies;
  final String dateOfBirth,
      bloodType,
      chronicDiseases,
      emergencyContact,
      identityCard;
  final String clinicRoom;
  final bool isLoaded;
  final VoidCallback onEdit;

  const _PatientInfoCard({
    required this.name,
    required this.phone,
    required this.gender,
    required this.address,
    required this.medicalHistory,
    required this.allergies,
    required this.dateOfBirth,
    required this.bloodType,
    required this.chronicDiseases,
    required this.emergencyContact,
    required this.identityCard,
    required this.clinicRoom,
    required this.isLoaded,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = dateOfBirth.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: hasError ? Colors.red.shade200 : Colors.transparent),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: isLoaded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hồ sơ sức khỏe',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _kPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: _kPrimary, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Chỉnh sửa',
                    ),
                  ],
                ),
                if (hasError)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '* Bắt buộc nhập Ngày sinh để tiếp tục',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const Divider(height: 12),
                _InfoRow(
                    icon: Icons.person_outline, value: name, label: 'Họ tên'),
                _InfoRow(
                    icon: Icons.cake_outlined,
                    value: dateOfBirth,
                    label: 'Ngày sinh'),
                _InfoRow(
                    icon: Icons.badge_outlined,
                    value: identityCard,
                    label: 'Số CCCD'),
                _InfoRow(
                    icon: Icons.wc_outlined, value: gender, label: 'Giới tính'),
                _InfoRow(
                    icon: Icons.bloodtype_outlined,
                    value: bloodType,
                    label: 'Nhóm máu'),
                _InfoRow(
                    icon: Icons.phone_outlined, value: phone, label: 'SĐT'),
                if (emergencyContact.isNotEmpty)
                  _InfoRow(
                      icon: Icons.contact_emergency_outlined,
                      value: _formatEmergencyContactString(emergencyContact),
                      label: 'Khẩn cấp'),
                _InfoRow(
                    icon: Icons.location_on_outlined,
                    value: address,
                    label: 'Địa chỉ'),
                if (medicalHistory.isNotEmpty)
                  _InfoRow(
                      icon: Icons.history_outlined,
                      value: medicalHistory,
                      label: 'Tiền sử'),
                if (chronicDiseases.isNotEmpty)
                  _InfoRow(
                      icon: Icons.coronavirus_outlined,
                      value: chronicDiseases,
                      label: 'Bệnh nền'),
                if (allergies.isNotEmpty)
                  _InfoRow(
                      icon: Icons.warning_amber_outlined,
                      value: allergies,
                      label: 'Dị ứng'),
                if (clinicRoom.isNotEmpty)
                  _InfoRow(
                      icon: Icons.meeting_room_outlined,
                      value: clinicRoom,
                      label: 'Phòng khám'),
              ],
            )
          : const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _InfoRow(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Image upload section with upload progress and preview.
class _ImageUploadSection extends ConsumerWidget {
  final String doctorId;
  const _ImageUploadSection({required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider(doctorId));
    final notifier = ref.read(bookingProvider(doctorId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.image_outlined,
          label: 'Ảnh triệu chứng (tùy chọn)',
        ),
        const SizedBox(height: 10),
        if (state.isUploadingImage) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary),
                ),
                SizedBox(width: 8),
                Text('Đang tải ảnh lên...',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.imageUrls.length + 1,
            itemBuilder: (context, index) {
              if (index == state.imageUrls.length) {
                return GestureDetector(
                  onTap: state.isUploadingImage
                      ? null
                      : notifier.pickAndUploadImage,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 28, color: Colors.grey.shade400),
                        const SizedBox(height: 4),
                        const Text(
                          'Thêm ảnh',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final imgUrl = state.imageUrls[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => notifier.removeImageAtIndex(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Horizontal date chip row for selecting a booking date.
class _DatePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerRow({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Show next 14 days
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrollable date chips
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (ctx, i) {
              final day = days[i];
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;
              final isToday = day.day == today.day && day.month == today.month;

              return GestureDetector(
                onTap: () => onDateSelected(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary : _kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _kPrimary : Colors.grey.shade300,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _kPrimary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E', 'vi_VN').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (isToday)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : _kPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('MMMM yyyy', 'vi_VN').format(selectedDate),
          style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// [Booking-4] Time slot grid with styled chip buttons.
///
/// Shows all available 30-minute slots for the selected date.
/// Selected slot is highlighted with Primary Blue.
/// Past slots are greyed out and unselectable.
class _TimeSlotGrid extends ConsumerWidget {
  final DateTime selectedDate;
  final String doctorId;

  const _TimeSlotGrid({
    required this.selectedDate,
    required this.doctorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider(doctorId));
    final notifier = ref.read(bookingProvider(doctorId).notifier);

    // Fetch booked slots for the selected date
    final dateStr =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final bookedSlotsAsync =
        ref.watch(bookedSlotsProvider((doctorId: doctorId, date: dateStr)));

    return bookedSlotsAsync.when(
      loading: () => const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: _kPrimary),
      )),
      error: (err, _) => Center(child: Text('Lỗi tải khung giờ: $err')),
      data: (bookedSlots) {
        final slots = getAvailableSlots(selectedDate, bookedSlots);

        if (slots.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Không còn ca khám trong ngày hôm nay hoặc giờ đã được đặt hết.\nVui lòng chọn ngày khác.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Morning slots
              _SlotGroup(
                label: '☀️ Buổi sáng',
                slots: slots.where((s) => s.hour < 12).toList(),
                selectedSlot: bookingState.timeSlot,
                onSelect: notifier.selectTimeSlot,
              ),
              const SizedBox(height: 14),
              // Afternoon slots
              _SlotGroup(
                label: '🌤️ Buổi chiều',
                slots: slots.where((s) => s.hour >= 13).toList(),
                selectedSlot: bookingState.timeSlot,
                onSelect: notifier.selectTimeSlot,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SlotGroup extends StatelessWidget {
  final String label;
  final List<DateTime> slots;
  final DateTime? selectedSlot;
  final ValueChanged<DateTime> onSelect;

  const _SlotGroup({
    required this.label,
    required this.slots,
    required this.selectedSlot,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const double spacing = 10.0;
            const int crossAxisCount = 4;
            final double totalSpacing = spacing * (crossAxisCount - 1);
            final double itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: slots.map((slot) {
                final isSelected = selectedSlot != null &&
                    selectedSlot!.hour == slot.hour &&
                    selectedSlot!.minute == slot.minute &&
                    selectedSlot!.day == slot.day;

                return GestureDetector(
                  onTap: () => onSelect(slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: itemWidth,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _kPrimary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _kPrimary.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_circle_rounded,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          DateFormat('HH:mm').format(slot),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Submit button with loading state overlay.
class _SubmitButton extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final String doctorId;
  final Map<String, dynamic> doctor;
  final String patientName, phone, gender, address, medicalHistory, allergies;
  final String dateOfBirth,
      bloodType,
      chronicDiseases,
      emergencyContact,
      identityCard;
  final String paymentMethod;
  final bool isSubmitting;

  const _SubmitButton({
    required this.formKey,
    required this.doctorId,
    required this.doctor,
    required this.patientName,
    required this.phone,
    required this.gender,
    required this.address,
    required this.medicalHistory,
    required this.allergies,
    required this.dateOfBirth,
    required this.bloodType,
    required this.chronicDiseases,
    required this.emergencyContact,
    required this.identityCard,
    required this.paymentMethod,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: isSubmitting ? 0 : 3,
        ),
        onPressed: isSubmitting
            ? null
            : () async {
// 3. KIỂM TRA LÝ DO KHÁM (FORM VALIDATION)
                if (!formKey.currentState!.validate()) {
                  return; // Dừng lại nếu chưa nhập lý do khám
                }
                final state = ref.read(bookingProvider(doctorId));
                if (state.timeSlot == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn ngày và giờ khám!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (identityCard.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Vui lòng cập nhật Số CCCD trong Hồ sơ sức khỏe!')),
                  );
                  return;
                }
                if (dateOfBirth.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Vui lòng cập nhật Ngày sinh trong Hồ sơ sức khỏe!')),
                  );
                  return;
                }

                // Auto-save profile first
                try {
                  Map<String, String>? emergencyObj;
                  if (emergencyContact.isNotEmpty) {
                    final parts = emergencyContact.split('-');
                    if (parts.length >= 2) {
                      emergencyObj = {
                        "name": parts[0].trim(),
                        "phone": parts.sublist(1).join('-').trim(),
                      };
                    } else {
                      emergencyObj = {
                        "name": emergencyContact.trim(),
                        "phone": "",
                      };
                    }
                  }
                  await ApiService.updateProfile({
                    "profile": {
                      "phone": phone,
                      "gender": gender,
                      "address": address,
                      "medicalHistory": medicalHistory,
                      "allergies": allergies,
                      "dateOfBirth": dateOfBirth,
                      "bloodType": bloodType,
                      "chronicDiseases": chronicDiseases,
                      "emergencyContact": emergencyObj,
                      "identityCard": identityCard,
                    }
                  });
                } catch (e) {
                  // ignore error, proceed with booking
                }

                // Robust extraction of doctorId and departmentId
                // 1. Lấy Doctor ID
                final String resolvedDocId = doctor['_id']?.toString() ??
                    doctor['id']?.toString() ??
                    doctorId;

                // 2. Lấy Department ID - Quét mọi ngóc ngách
                String resolvedDeptId = '';

                // Bước 2.1: Thử lấy ở vòng ngoài
                dynamic rawDept =
                    doctor['departmentId'] ?? doctor['department'];

                // Bước 2.2: Nếu ngoài bị null, chui vào trong roomId để "moi" specialtyId ra (Dựa theo JSON thực tế)
                if (rawDept == null && doctor['roomId'] is Map) {
                  rawDept = doctor['roomId']['specialtyId'];
                }

                // Bước 2.3: Parse dữ liệu
                if (rawDept != null) {
                  if (rawDept is Map) {
                    resolvedDeptId = rawDept['_id']?.toString() ??
                        rawDept['id']?.toString() ??
                        '';
                  } else {
                    resolvedDeptId = rawDept.toString();
                  }
                }

                // 3. CHẶN LỖI (Vẫn giữ nguyên lớp bảo vệ)
                if (resolvedDeptId.trim().isEmpty) {
                  print(
                      "🚨 LỖI: Object doctor bị thiếu thông tin khoa: $doctor");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Lỗi: Bác sĩ này chưa thuộc chuyên khoa nào!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (resolvedDeptId.isEmpty) {
                  resolvedDeptId = doctor['specialtyId_id']?.toString() ??
                      doctor['specialtyId']?.toString() ??
                      doctor['specialty_id']?.toString() ??
                      '';
                }

                ref.read(bookingProvider(doctorId).notifier).submitBooking(
                      doctorId: resolvedDocId,
                      departmentId: resolvedDeptId,
                      patientName: patientName,
                      phone: phone,
                      gender: gender,
                      address: address,
                      medicalHistory: medicalHistory,
                      allergies: allergies,
                      cccd: identityCard,
                      birthDate: dateOfBirth,
                      paymentMethod: paymentMethod,
                    );
              },
        child: isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Đang xử lý...', style: TextStyle(fontSize: 16)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Xác nhận đặt lịch',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A row in the success dialog.
class _SuccessInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SuccessInfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kPrimary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ── Shared input decoration ───────────────────────────────────────────────────
InputDecoration _inputDeco({required String hint, IconData? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: _kPrimary, size: 20)
        : null,
    filled: true,
    fillColor: _kSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kPrimary, width: 2),
    ),
  );
}
