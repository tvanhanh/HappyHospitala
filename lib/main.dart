import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- IMPORT CÁC MÀN HÌNH ---
// 1. Auth
import 'screens/screen_authencication/login_screen.dart';

// 2. Patient
import './screens/screen_patient/home_screen.dart';
import 'screens/screen_patient/thank_screen.dart';

// 3. Admin & Staff
import 'screens/screens_admin/home.dart';
import 'screens/screen_staff/home.dart';

// 4. Doctor Screens
import 'screens/screen_doctor/doctor_home_screen.dart';
import './screens/screen_doctor/appointment_page.dart';
import './screens/screen_doctor/patient_management.dart';
import './screens/screen_doctor/prescription.dart';
import './screens/screen_doctor/classification_results.dart';
import './screens/screen_doctor/consultation.dart';
import './screens/screen_doctor/progress_tracking.dart';

// --- CẤU HÌNH MÀU SẮC CHỦ ĐẠO ---
const Color kPrimaryColor = Color(0xFF1565C0); // Xanh dương đậm

void main() async {
  // ✅ Bắt buộc phải có để khởi tạo các dịch vụ trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo dữ liệu định dạng ngày tháng Tiếng Việt
  await initializeDateFormatting('vi', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Đã sửa lại constructor chuẩn cho StatelessWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // <-- ĐÃ SỬA: Dùng MaterialApp tiêu chuẩn
      debugShowCheckedModeBanner: false,
      title: 'Smart Clinic - Đặt lịch khám bệnh',

      // --- THIẾT LẬP THEME TOÀN CỤC ---
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: kPrimaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),

      initialRoute: '/', // Màn hình đầu tiên

      // --- ĐỊNH NGHĨA ROUTES (ĐÃ GIỮ NGUYÊN CỦA BẠN) ---
      routes: {
        // Auth
        '/': (context) => LoginScreen(),

        // Patient
        '/home': (context) => HomeScreen(),
        '/thankyou': (context) => ThankYouScreen(),

        // Admin & Staff
        '/admin': (context) => AdminDashboard(),
        '/staff': (context) => StaffDashboard(),

        // Doctor Flows
        '/doctor': (context) => DoctorDashboard(),
        '/appointments': (context) => AppointmentPage(),
        '/prescription': (context) => PrescriptionPage(),
        '/patient-management': (context) => PatientManagementPage(),
        '/classification-results': (context) => ClassificationResultsPage(),
        '/consultation': (context) => ConsultationPage(),
        '/progress-tracking': (context) => ProgressTrackingPage(),
      },
    );
  }
}
