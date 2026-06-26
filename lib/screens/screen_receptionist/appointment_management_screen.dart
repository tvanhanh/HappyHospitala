import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../providers/receptionist_provider.dart';
import '../../widgets/receptionist_drawer.dart';
import '../../providers/auth_provider.dart';
import 'notificationScreen.dart';
import '../../widgets/appointment_form_dialog.dart';
import '../../services/api_appointment.dart';

class ReceptionistCheckListScreen extends ConsumerStatefulWidget {
  const ReceptionistCheckListScreen({super.key});

  @override
  ConsumerState<ReceptionistCheckListScreen> createState() =>
      _ReceptionistDashboardScreenState();
}

class _ReceptionistDashboardScreenState
    extends ConsumerState<ReceptionistCheckListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Appointment? _selectedAppointment;

  // Scheduler & calendar view state
  String _schedulerViewMode = "day"; // "day", "week", "month"
  List<Appointment> _allAppointments = [];
  bool _loadingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(receptionistProvider);
      ref.read(receptionistProvider.notifier).fetchAppointments(state.selectedDate);
      _loadAllAppointments();
      ref.read(receptionistProvider.notifier).fetchTriageHandoffs();
    });
  }

  Future<void> _loadAllAppointments() async {
    if (!mounted) return;
    setState(() {
      _loadingAll = true;
    });
    try {
      final list = await AppointmentApi.getAllAppointments();
      if (mounted) {
        setState(() {
          _allAppointments = list;
          _loadingAll = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAll = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final state = ref.read(receptionistProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != state.selectedDate) {
      ref.read(receptionistProvider.notifier).fetchAppointments(picked);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFF3E0); // light orange
      case 'confirmed':
        return const Color(0xFFE3F2FD); // light blue
      case 'checked_in':
        return const Color(0xFFE8F5E9); // light green
      case 'in_progress':
        return const Color(0xFFF3E5F5); // light purple
      case 'completed':
        return const Color(0xFFE0F2F1); // light teal
      case 'cancelled':
        return const Color(0xFFFFEBEE); // light red
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE65100); // orange
      case 'confirmed':
        return const Color(0xFF0D47A1); // blue
      case 'checked_in':
        return const Color(0xFF2E7D32); // green
      case 'in_progress':
        return const Color(0xFF7B1FA2); // purple
      case 'completed':
        return const Color(0xFF00695C); // teal
      case 'cancelled':
        return const Color(0xFFC62828); // red
      default:
        return const Color(0xFF616161);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checked_in':
        return 'Đã Check-in';
      case 'in_progress':
        return 'Đang khám';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không rõ';
    }
  }

  void _showCheckInDialog(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 28),
            SizedBox(width: 8),
            Text(
              "Xác Nhận Check-In",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Vui lòng xác minh thông tin bệnh nhân trước khi check-in:",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildDialogInfoRow("Mã đặt lịch:", "#${appointment.id.toUpperCase()}"),
              _buildDialogInfoRow("Họ và tên:", appointment.patientName),
              _buildDialogInfoRow("CCCD/CMND:", appointment.cccd.isNotEmpty ? appointment.cccd : "Chưa cập nhật"),
              _buildDialogInfoRow("Số điện thoại:", appointment.phone),
              _buildDialogInfoRow("Bác sĩ khám:", appointment.doctorName),
              _buildDialogInfoRow("Chuyên khoa:", appointment.departmentName.isNotEmpty ? appointment.departmentName : appointment.doctorSpecialty),
              _buildDialogInfoRow("Giờ hẹn:", "${appointment.time} - ${appointment.date}"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bệnh nhân sẽ được xếp vào hàng chờ trực tiếp của Bác sĩ.",
                        style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref
                  .read(receptionistProvider.notifier)
                  .checkInPatient(appointment.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.white),
                          const SizedBox(width: 8),
                          Text("Đã check-in thành công cho ${appointment.patientName}"),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  final errorMsg = ref.read(receptionistProvider).errorMessage ?? "Đã xảy ra lỗi";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMsg)),
                        ],
                      ),
                      backgroundColor: const Color(0xFFC62828),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Xác Nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF555555), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF222222), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAppointment(Appointment appt) {
    setState(() {
      _selectedAppointment = appt;
    });
    
    final width = MediaQuery.of(context).size.width;
    if (width < 1000) {
      _showDetailDialog(appt);
    }
  }

  void _showDetailDialog(Appointment appt) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 450,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SelectionArea(
              child: _buildAdministrativeDetailPanel(appt, isDialog: true),
            ),
          ),
        );
      },
    );
  }

  DateTime _findFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return "Thứ 2";
      case 2: return "Thứ 3";
      case 3: return "Thứ 4";
      case 4: return "Thứ 5";
      case 5: return "Thứ 6";
      case 6: return "Thứ 7";
      case 7: return "Chủ Nhật";
      default: return "";
    }
  }

  void _shiftDate(int days) {
    final state = ref.read(receptionistProvider);
    final newDate = state.selectedDate.add(Duration(days: days));
    ref.read(receptionistProvider.notifier).fetchAppointments(newDate);
  }

  void _shiftMonth(int months) {
    final state = ref.read(receptionistProvider);
    final newDate = DateTime(state.selectedDate.year, state.selectedDate.month + months, state.selectedDate.day);
    ref.read(receptionistProvider.notifier).fetchAppointments(newDate);
  }

  String _getNavigationLabel(DateTime date) {
    if (_schedulerViewMode == "day") {
      return "Ngày ${DateFormat('dd/MM/yyyy').format(date)}";
    } else if (_schedulerViewMode == "week") {
      final start = _findFirstDayOfWeek(date);
      final end = start.add(const Duration(days: 6));
      return "Tuần ${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}";
    } else {
      return "Tháng ${DateFormat('MM/yyyy').format(date)}";
    }
  }

  Widget _buildViewModeButton(String mode, String label, IconData icon) {
    final isActive = _schedulerViewMode == mode;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _schedulerViewMode = mode;
          });
          if (mode != "day") {
            _loadAllAppointments();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0D47A1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF0D47A1).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekScheduler(DateTime selectedDate) {
    final startOfWeek = _findFirstDayOfWeek(selectedDate);
    final days = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        
        if (isMobile) {
          return Column(
            children: days.map((day) => _buildWeekDayRow(day)).toList(),
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: days.map((day) => Expanded(child: _buildWeekDayColumn(day))).toList(),
          );
        }
      },
    );
  }

  Widget _buildWeekDayColumn(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    final isToday = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isSelected = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(ref.read(receptionistProvider).selectedDate);
    
    final dayAppointments = _allAppointments.where((appt) => appt.date == dayStr).toList();

    return GestureDetector(
      onTap: () {
        ref.read(receptionistProvider.notifier).fetchAppointments(day);
        setState(() {
          _schedulerViewMode = "day";
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2).withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1976D2) : (isToday ? const Color(0xFF2E7D32) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getWeekdayName(day.weekday),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? const Color(0xFF1976D2) : const Color(0xFF222222),
              ),
            ),
            Text(
              DateFormat('dd/MM').format(day),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (dayAppointments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Trống",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ),
              )
            else
              ...dayAppointments.take(3).map((appt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildMiniAppointmentCardCompact(appt),
                );
              }),
            if (dayAppointments.length > 3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "+${dayAppointments.length - 3} lịch",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDayRow(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    final dayAppointments = _allAppointments.where((appt) => appt.date == dayStr).toList();
    final isToday = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return InkWell(
      onTap: () {
        ref.read(receptionistProvider.notifier).fetchAppointments(day);
        setState(() {
          _schedulerViewMode = "day";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getWeekdayName(day.weekday),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? const Color(0xFF2E7D32) : const Color(0xFF222222),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(day),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: dayAppointments.isEmpty
                  ? Text("Trống", style: TextStyle(color: Colors.grey.shade400, fontSize: 12))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: dayAppointments.map((appt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: _buildMiniAppointmentCardCompact(appt),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAppointmentCardCompact(Appointment appt) {
    Color statusColor = Colors.grey;
    switch (appt.status) {
      case 'pending': statusColor = Colors.orange; break;
      case 'confirmed': statusColor = Colors.blue; break;
      case 'checked_in': statusColor = const Color(0xFF1976D2); break;
      case 'completed': statusColor = const Color(0xFF2E7D32); break;
      case 'cancelled': statusColor = Colors.red; break;
    }

    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _selectAppointment(appt),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        appt.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF222222)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${appt.time} • BS.${appt.doctorName.split(' ').last}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthScheduler(DateTime selectedDate) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    
    final daysInMonth = lastDayOfMonth.day;
    final weekdayOfFirstDay = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    final paddingCells = weekdayOfFirstDay - 1;
    final totalCells = paddingCells + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    
    return Column(
      children: [
        Row(
          children: List.generate(7, (index) {
            final dayName = _getWeekdayName(index + 1);
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    dayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF222222)),
                  ),
                ),
              ),
            );
          }),
        ),
        const Divider(height: 1),
        ...List.generate(rowCount, (rowIndex) {
          return Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              if (cellIndex < paddingCells || cellIndex >= totalCells) {
                return const Expanded(child: SizedBox(height: 60));
              }
              
              final dayNumber = cellIndex - paddingCells + 1;
              final cellDate = DateTime(selectedDate.year, selectedDate.month, dayNumber);
              final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);
              final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
              final isSelected = dateStr == DateFormat('yyyy-MM-dd').format(ref.read(receptionistProvider).selectedDate);
              
              final dayAppointments = _allAppointments.where((appt) => appt.date == dateStr).toList();
              
              return Expanded(
                child: InkWell(
                  onTap: () {
                    ref.read(receptionistProvider.notifier).fetchAppointments(cellDate);
                    setState(() {
                      _schedulerViewMode = "day";
                    });
                  },
                  child: Container(
                    height: 70,
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1976D2).withOpacity(0.04) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1976D2) : (isToday ? const Color(0xFF2E7D32) : const Color(0xFFE2E8F0).withOpacity(0.5)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                            color: isSelected ? const Color(0xFF1976D2) : (isToday ? const Color(0xFF2E7D32) : const Color(0xFF222222)),
                          ),
                        ),
                        const Spacer(),
                        if (dayAppointments.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: Color(0xFF1976D2), size: 6),
                                const SizedBox(width: 4),
                                Text(
                                  "${dayAppointments.length} ca",
                                  style: const TextStyle(
                                    color: Color(0xFF1976D2),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final receptionistState = ref.watch(receptionistProvider);
    final appointments = receptionistState.filteredAppointments;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    // Calculate metrics based on the full list of today's appointments
    int totalCount = receptionistState.appointments.length;
    int checkedInCount = receptionistState.appointments.where((a) => a.status == 'checked_in').length;
    int waitingCount = receptionistState.appointments.where((a) => ['pending', 'confirmed'].contains(a.status)).length;
    int doneCount = receptionistState.appointments.where((a) => ['completed'].contains(a.status)).length;

    // Filter appointments for each tab locally
    final checkedInList = appointments.where((a) => a.status == 'checked_in').toList();
    final toCheckInList = appointments.where((a) => ['pending', 'confirmed'].contains(a.status)).toList();
    final triageHandoffs = receptionistState.triageHandoffs;
    final state = ref.watch(receptionistProvider);
    final userState = ref.watch(authProvider);
    

  return DefaultTabController(
    length: 4,
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      // LUÔN LUÔN hiển thị AppBar này trên cả Mobile lẫn Desktop để đồng bộ màu xanh
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1), // Màu xanh đồng bộ như hình
        elevation: 0, // Xóa bóng mờ phía dưới thanh để tạo cảm giác phẳng
        centerTitle: true,
        
        // 1. Nút Menu 3 gạch ở góc trái (Tự động bo tròn nhẹ khi di chuột vào giống ảnh)
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: "Open navigation menu", // Tooltip xuất hiện như trong ảnh của bạn
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Mở Menu bên trái
              },
            );
          },
        ),
        
        // 2. Tiêu đề chính nằm ở giữa thanh xanh
        title: const Text(
          "Happy Clinic - Hệ thống quản lý",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 18, 
            color: Colors.white,
          ),
        ),
        
        // 3. Nút Refresh (vòng xoay) nằm ở góc phải
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(receptionistProvider.notifier).fetchAppointments(receptionistState.selectedDate);
            },
          ),
          const SizedBox(width: 8), // Khoảng cách nhỏ với mép phải
        ],
      ),
      
      // Thanh Menu Drawer kéo ra từ bên trái
      drawer: const ReceptionistDrawer(
        selectedMenu: "Quản lý lịch hẹn",
      ),
        body: Row(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Date Picker Action
                
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Quản Lý Check-In Khách Hàng",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                                const SizedBox(height: 4),
                               
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () =>{context.push("/receptionist/notification")},
                              icon: const Icon(Icons.notification_add, size: 14, color: Colors.white),
                              label: const Text("Thông báo", style: TextStyle(color: Colors.white, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Statistics summary row / grid
                      if (isDesktop)
                        Row(
                          children: [
                            Expanded(child: _buildStatCard("Tất cả lịch hẹn", totalCount.toString(), Icons.event_note, const Color(0xFF1976D2))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatCard("Chờ Check-in", waitingCount.toString(), Icons.hourglass_empty, const Color(0xFFFFA000))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatCard("Đã Check-in", checkedInCount.toString(), Icons.check_circle_outline, const Color(0xFF2E7D32))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatCard("Đã khám xong", doneCount.toString(), Icons.done_all, const Color(0xFF008080))),
                          ],
                        )
                      else
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.3,
                          children: [
                            _buildStatCard("Tất cả lịch hẹn", totalCount.toString(), Icons.event_note, const Color(0xFF1976D2)),
                            _buildStatCard("Chờ Check-in", waitingCount.toString(), Icons.hourglass_empty, const Color(0xFFFFA000)),
                            _buildStatCard("Đã Check-in", checkedInCount.toString(), Icons.check_circle_outline, const Color(0xFF2E7D32)),
                            _buildStatCard("Đã khám xong", doneCount.toString(), Icons.done_all, const Color(0xFF008080)),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Top search bar & Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  ref.read(receptionistProvider.notifier).search(val);
                                },
                                decoration: InputDecoration(
                                  hintText: "Tìm kiếm theo Tên bệnh nhân, Mã đặt lịch, CCCD hoặc Số điện thoại...",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.grey),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(receptionistProvider.notifier).search('');
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () => _selectDate(context),
                                icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                                label: const Text("Chọn Ngày Khám", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D47A1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  elevation: 0,
                                ),
                              ),
                            ),
                             const SizedBox(width: 16),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return const AppointmentFormDialog(); // Khởi tạo dialog của bạn ở đây
        },
      );},
                                icon: const Icon(Icons.add_alarm, size: 16, color: Colors.white),
                                label: const Text("Thêm mới", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D47A1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ─── VIEW MODE SWITCHER & NAVIGATION ───
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // View mode toggle buttons
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildViewModeButton("day", "Ngày", Icons.today_rounded),
                                  _buildViewModeButton("week", "Tuần", Icons.view_week_rounded),
                                  _buildViewModeButton("month", "Tháng", Icons.calendar_month_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Navigation: prev button
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  if (_schedulerViewMode == "day") _shiftDate(-1);
                                  else if (_schedulerViewMode == "week") _shiftDate(-7);
                                  else _shiftMonth(-1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF64748B)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Date label
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                final now = DateTime.now();
                                ref.read(receptionistProvider.notifier).fetchAppointments(now);
                                _loadAllAppointments();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getNavigationLabel(receptionistState.selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Navigation: next button
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  if (_schedulerViewMode == "day") _shiftDate(1);
                                  else if (_schedulerViewMode == "week") _shiftDate(7);
                                  else _shiftMonth(1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF64748B)),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Today button
                            TextButton.icon(
                              onPressed: () {
                                final now = DateTime.now();
                                ref.read(receptionistProvider.notifier).fetchAppointments(now);
                                _loadAllAppointments();
                              },
                              icon: const Icon(Icons.today, size: 16, color: Color(0xFF0D47A1)),
                              label: const Text("Hôm nay", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── CONDITIONAL VIEW: Calendar or Day Tabs ───
                      if (_schedulerViewMode == "week")
                        Expanded(
                          child: _loadingAll
                              ? const Center(child: CircularProgressIndicator())
                              : SingleChildScrollView(
                                  child: _buildWeekScheduler(receptionistState.selectedDate),
                                ),
                        )
                      else if (_schedulerViewMode == "month")
                        Expanded(
                          child: _loadingAll
                              ? const Center(child: CircularProgressIndicator())
                              : SingleChildScrollView(
                                  child: _buildMonthScheduler(receptionistState.selectedDate),
                                ),
                        )
                      else ...[
                        // Day mode: show TabBar + TabBarView
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200, width: 1),
                          ),
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: const Color(0xFF0D47A1),
                            unselectedLabelColor: Colors.grey.shade600,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.hourglass_empty_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text("Chờ Check-in (${toCheckInList.length})"),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.queue_play_next_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text("Hàng chờ khám (${checkedInList.length})"),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.list_alt_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text("Tất cả (${appointments.length})"),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.support_agent_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text("Bàn giao (${triageHandoffs.length})"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: receptionistState.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : TabBarView(
                                  children: [
                                    // Tab 1: To Check-in List
                                    RefreshIndicator(
                                      onRefresh: () => ref.read(receptionistProvider.notifier).fetchAppointments(receptionistState.selectedDate),
                                      child: toCheckInList.isEmpty
                                          ? _buildEmptyState("Không có bệnh nhân chờ check-in.")
                                          : isDesktop
                                              ? _buildDesktopTableView(toCheckInList)
                                              : ListView.builder(
                                                  physics: const AlwaysScrollableScrollPhysics(),
                                                  itemCount: toCheckInList.length,
                                                  itemBuilder: (context, index) {
                                                    return _buildAppointmentCard(toCheckInList[index]);
                                                  },
                                                ),
                                    ),
                                    // Tab 2: Live Queue (Checked-in)
                                    RefreshIndicator(
                                      onRefresh: () => ref.read(receptionistProvider.notifier).fetchAppointments(receptionistState.selectedDate),
                                      child: checkedInList.isEmpty
                                          ? _buildEmptyState("Hàng chờ trực tiếp đang trống.")
                                          : isDesktop
                                              ? _buildDesktopTableView(checkedInList)
                                              : ListView.builder(
                                                  physics: const AlwaysScrollableScrollPhysics(),
                                                  itemCount: checkedInList.length,
                                                  itemBuilder: (context, index) {
                                                    return _buildAppointmentCard(checkedInList[index]);
                                                  },
                                                ),
                                    ),
                                    // Tab 3: All Appointments
                                    RefreshIndicator(
                                      onRefresh: () => ref.read(receptionistProvider.notifier).fetchAppointments(receptionistState.selectedDate),
                                      child: appointments.isEmpty
                                          ? _buildEmptyState("Không có lịch hẹn nào.")
                                          : isDesktop
                                              ? _buildDesktopTableView(appointments)
                                              : ListView.builder(
                                                  physics: const AlwaysScrollableScrollPhysics(),
                                                  itemCount: appointments.length,
                                                  itemBuilder: (context, index) {
                                                    return _buildAppointmentCard(appointments[index]);
                                                  },
                                                ),
                                    ),
                                    // Tab 4: Triage Handoffs
                                    receptionistState.isHandoffLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : triageHandoffs.isEmpty
                                            ? _buildEmptyState("Không có yêu cầu bàn giao nào.")
                                            : _buildTriageHandoffsList(triageHandoffs),
                                  ],
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // ─── ADMINISTRATIVE DETAIL PANEL (Desktop split-screen) ───
            if (isDesktop && _selectedAppointment != null)
              Container(
                width: 420,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: _buildAdministrativeDetailPanel(_selectedAppointment!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    String selectedMenu,
  ) {
    final isSelected = selectedMenu == title;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.08),
          splashColor: Colors.white.withOpacity(0.12),
          onTap: () => context.go(route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarProfile(BuildContext context, authState) {
    final name = authState.name ?? "Lễ tân HappyClinic";
    final avatarUrl = authState.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3C8F),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            radius: 20,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "Lễ tân",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
            tooltip: "Đăng xuất",
            onPressed: () async {
              // Confirm logout
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text("Xác nhận đăng xuất"),
                  content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/auth/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                      ),
                      child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget _buildDesktopHeader(BuildContext context, receptionistState) {
  //   return Container(
  //     padding: const EdgeInsets.only(bottom: 24),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Builder(
  //         builder: (context) {
  //           return IconButton(
  //             icon: const Icon(Icons.menu, color: Color(0xFF0D47A1), size: 28),
  //             onPressed: () {
  //               Scaffold.of(context).openDrawer(); // Mở Drawer của Scaffold chứa nó
  //             },
  //           );
  //         },
  //       ),
      
  //               const SizedBox(height: 6),
  //               const Text(
  //                 "Quản Lý Check-In Khách Hàng",
  //                 style: TextStyle(
  //                   fontSize: 28,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF0D47A1),
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 "Ngày làm việc: ${DateFormat('dd/MM/yyyy').format(receptionistState.selectedDate)}",
  //                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
  //               ),
  //             ],
  //           ),
  //         ),
  //         // Actions on the right
  //         ElevatedButton.icon(
  //           onPressed: () {
  //             ref.read(receptionistProvider.notifier).fetchAppointments(receptionistState.selectedDate);
  //           },
  //           icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
  //           label: const Text("Tải lại", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: const Color(0xFF0D47A1),
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  //             elevation: 0,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState([String subtitle = "Không tìm thấy lịch hẹn nào phù hợp với bộ lọc hiện tại."]) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  "Không có lịch hẹn nào",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final status = appointment.status;
    final isCanCheckIn = ['pending', 'confirmed'].contains(status);
    final shortId = appointment.id.length > 8
        ? appointment.id.substring(appointment.id.length - 8).toUpperCase()
        : appointment.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _getStatusTextColor(status),
                width: 6,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: ID & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Mã LH: #$shortId",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (appointment.paymentMethod == 'insurance')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "BHYT",
                            style: TextStyle(fontSize: 10, color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        color: _getStatusTextColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.8),

              // Patient Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1976D2).withOpacity(0.08),
                    radius: 22,
                    child: const Icon(Icons.person, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(appointment.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(width: 16),
                            Icon(Icons.credit_card, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              appointment.cccd.isNotEmpty ? appointment.cccd : "BHYT/CCCD: N/A",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        appointment.time,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      Text(
                        appointment.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Doctor & Reason block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Bác sĩ: ",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          appointment.doctorName,
                          style: const TextStyle(color: Color(0xFF333333), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(${appointment.departmentName.isNotEmpty ? appointment.departmentName : appointment.doctorSpecialty})",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Triệu chứng: ",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Expanded(
                          child: Text(
                            appointment.reason.isNotEmpty ? appointment.reason : "Không mô tả",
                            style: const TextStyle(color: Color(0xFF555555), fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Check-In Button or State indication
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isCanCheckIn)
                    ElevatedButton.icon(
                      onPressed: () => _showCheckInDialog(context, appointment),
                      icon: const Icon(Icons.verified_user_outlined, size: 16, color: Colors.white),
                      label: const Text("Xác minh & Check-In", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 1,
                      ),
                    )
                  else if (status == 'checked_in')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: Color(0xFF2E7D32), size: 16),
                          SizedBox(width: 6),
                          Text(
                            "Đã Check-In (Đang trong hàng chờ)",
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Lịch khám ở trạng thái: ${_getStatusLabel(status)}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTableView(List<Appointment> list) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.12), width: 1),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 2,
                child: Text(
                  "MÃ LH",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  "BỆNH NHÂN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "LỊCH HẸN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "BÁC SĨ & KHOA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "TRẠNG THÁI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "THAO TÁC",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...list.map((a) => _buildDesktopAppointmentRow(a)),
      ],
    );
  }

  Widget _buildDesktopAppointmentRow(Appointment appointment) {
    final status = appointment.status;
    final isCanCheckIn = ['pending', 'confirmed'].contains(status);
    final shortId = appointment.id.length > 8
        ? appointment.id.substring(appointment.id.length - 8).toUpperCase()
        : appointment.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Material(
        color: _selectedAppointment?.id == appointment.id
            ? const Color(0xFF0D47A1).withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFF0D47A1).withOpacity(0.02),
          onTap: () => setState(() => _selectedAppointment = appointment),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 0.8),
            ),
            child: Row(
              children: [
                // Booking ID
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      ),
                      child: Text(
                        "#$shortId",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
                // Patient Info
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1976D2).withOpacity(0.08),
                        radius: 18,
                        child: const Icon(Icons.person, color: Color(0xFF1976D2), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  appointment.patientName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF222222)),
                                ),
                                if (appointment.paymentMethod == 'insurance') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
                                    ),
                                    child: const Text(
                                      "BHYT",
                                      style: TextStyle(fontSize: 9, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 11, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(appointment.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                if (appointment.cccd.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.credit_card, size: 11, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(appointment.cccd, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Schedule Date & Time
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF0D47A1)),
                          const SizedBox(width: 4),
                          Text(
                            appointment.time,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D47A1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(appointment.date, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                // Doctor & Department
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300, width: 0.5),
                        ),
                        child: Text(
                          appointment.departmentName.isNotEmpty ? appointment.departmentName : appointment.doctorSpecialty,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          color: _getStatusTextColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                // Action Button
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: isCanCheckIn
                        ? ElevatedButton.icon(
                            onPressed: () => _showCheckInDialog(context, appointment),
                            icon: const Icon(Icons.verified_user_outlined, size: 14, color: Colors.white),
                            label: const Text("Xác minh & Check-In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              elevation: 0,
                            ),
                          )
                        : status == 'checked_in'
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFC8E6C9)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, color: Color(0xFF2E7D32), size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      "Đang hàng chờ",
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusLabel(status),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRIAGE HANDOFFS LIST (Tab 4)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTriageHandoffsList(List<TriageHandoff> handoffs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: handoffs.length,
      itemBuilder: (context, index) {
        final handoff = handoffs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFA000).withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFFFFA000), width: 5)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFFA000).withOpacity(0.1),
                        radius: 22,
                        child: const Icon(Icons.support_agent_rounded, color: Color(0xFFFFA000), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              handoff.patientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF222222)),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(handoff.patientPhone, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(width: 12),
                                Text(
                                  "${handoff.patientGender} • ${handoff.patientDOB}",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF57C00)),
                            SizedBox(width: 4),
                            Text("Cần hỗ trợ", style: TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Symptoms preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200, width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            handoff.symptomsPreview,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await ref
                            .read(receptionistProvider.notifier)
                            .acceptHandoffChat(handoff.patientId);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Đã tiếp nhận cuộc trò chuyện với ${handoff.patientName}"),
                              backgroundColor: const Color(0xFF2E7D32),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          context.push('/receptionist/messenger');
                        }
                      },
                      icon: const Icon(Icons.headset_mic_outlined, size: 16, color: Colors.white),
                      label: const Text(
                        "Tiếp nhận cuộc trò chuyện",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57C00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMINISTRATIVE DETAIL PANEL (Desktop split-screen right side)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAdministrativeDetailPanel(Appointment appointment, {bool isDialog = false}) {
    final status = appointment.status;
    final isCanCheckIn = ['pending', 'confirmed'].contains(status);
    final typeLabel = appointment.appointmentType == 'online' ? '🎥 Khám Online (Video)' : '🏥 Khám tại phòng khám';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Chi tiết Hành chính",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
              ),
              IconButton(
                onPressed: isDialog
                    ? () => Navigator.of(context).pop()
                    : () => setState(() => _selectedAppointment = null),
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                tooltip: isDialog ? "Đóng hộp thoại" : "Đóng bảng chi tiết",
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),

          // Patient Avatar & Name
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1976D2).withOpacity(0.08),
                radius: 28,
                child: const Icon(Icons.person, color: Color(0xFF1976D2), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusLabel(status),
                            style: TextStyle(color: _getStatusTextColor(status), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: appointment.appointmentType == 'online'
                                ? const Color(0xFFE3F2FD)
                                : const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            appointment.appointmentType == 'online' ? 'Online' : 'Tại PK',
                            style: TextStyle(
                              color: appointment.appointmentType == 'online'
                                  ? const Color(0xFF0D47A1)
                                  : const Color(0xFF7B1FA2),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Demographics Section
          const Text(
            "THÔNG TIN NHÂN KHẨU",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          _buildDetailInfoRow(Icons.phone, "Số điện thoại", appointment.phone),
          _buildDetailInfoRow(Icons.credit_card, "CCCD/CMND", appointment.cccd.isNotEmpty ? appointment.cccd : "Chưa cập nhật"),
          _buildDetailInfoRow(Icons.cake_outlined, "Ngày sinh", appointment.birthDate.isNotEmpty ? appointment.birthDate : "Chưa rõ"),
          _buildDetailInfoRow(Icons.wc_rounded, "Giới tính", appointment.gender.isNotEmpty ? appointment.gender : "Chưa rõ"),
          _buildDetailInfoRow(Icons.location_on_outlined, "Địa chỉ", appointment.address.isNotEmpty ? appointment.address : "Chưa cập nhật"),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),

          // Appointment Info Section
          const Text(
            "THÔNG TIN LỊCH HẸN",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          _buildDetailInfoRow(Icons.medical_services_outlined, "Bác sĩ", appointment.doctorName),
          _buildDetailInfoRow(
            Icons.local_hospital_outlined,
            "Chuyên khoa",
            appointment.departmentName.isNotEmpty ? appointment.departmentName : appointment.doctorSpecialty,
          ),
          _buildDetailInfoRow(Icons.access_time_rounded, "Giờ hẹn", "${appointment.time} - ${appointment.date}"),
          _buildDetailInfoRow(Icons.category_outlined, "Hình thức", typeLabel),
          _buildDetailInfoRow(
            Icons.assignment_outlined,
            "Triệu chứng",
            appointment.reason.isNotEmpty ? appointment.reason : "Không mô tả",
          ),
          const SizedBox(height: 16),

          // Check-in Action Button
          if (isCanCheckIn) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCheckInDialog(context, appointment),
                icon: const Icon(Icons.verified_user_outlined, size: 18, color: Colors.white),
                label: const Text(
                  "📍 Xác nhận Check-in",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (status == 'checked_in') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Bệnh nhân đã Check-In.\nĐang trong hàng chờ khám Bác sĩ.",
                      style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Confirm appointment button (pending → confirmed)
          if (status == 'pending') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final success = await ref
                      .read(receptionistProvider.notifier)
                      .confirmAppointment(appointment.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Đã xác nhận lịch hẹn cho ${appointment.patientName}"),
                        backgroundColor: const Color(0xFF0D47A1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    // Refresh the selected appointment with the new status
                    setState(() {
                      _selectedAppointment = appointment.copyWith(status: 'confirmed');
                    });
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF0D47A1)),
                label: const Text(
                  "Xác nhận lịch hẹn",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D47A1)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0D47A1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Secure UI Guard (HIPAA Compliance)
          _buildSecureGuard(),
        ],
      ),
    );
  }

  Widget _buildDetailInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECURE UI GUARD (HIPAA/Data Privacy Compliance Placeholder)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSecureGuard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "🔒 Quyền truy cập bị hạn chế",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Nội dung bệnh án, Đơn thuốc điện tử và các dữ liệu AI/CNN/KNN chỉ được hiển thị cho Bác sĩ đã xác thực.\n\nLễ tân chỉ có quyền truy cập dữ liệu Hành chính / Hóa đơn.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}