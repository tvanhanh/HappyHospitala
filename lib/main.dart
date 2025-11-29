import 'package:flutter/material.dart';
// ✅ Import thư viện ngày tháng (Bắt buộc để không bị lỗi LocaleDataException)
import 'package:intl/date_symbol_data_local.dart';

// --- IMPORT CÁC MÀN HÌNH CỦA BẠN ---
import './screens/screen_patient/home_screen.dart';
import 'screens/screen_authencication/login_screen.dart';
import 'screens/screen_patient/thank_screen.dart';
import 'screens/screens_admin/home.dart';
import 'screens/screen_staff/home.dart';
import 'screens/screen_doctor/doctor_home_screen.dart';
import './screens/screen_doctor/appointment_page.dart';
import './screens/screen_doctor/patient_management.dart';
import './screens/screen_doctor/prescription.dart';
import './screens/screen_doctor/classification_results.dart';
import './screens/screen_doctor/consultation.dart';
import './screens/screen_doctor/progress_tracking.dart';

// --- MÀU SẮC CHỦ ĐẠO ---
const Color kPrimaryColor = Color(0xFF1565C0);

void main() async {
  // ✅ Dòng này bắt buộc khi dùng async trong main
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Dòng này sửa lỗi "LocaleDataException" khi dùng lịch/biểu đồ tiếng Việt
  await initializeDateFormatting('vi', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Đặt lịch khám bệnh',

      // --- CẤU HÌNH GIAO DIỆN ĐẸP TOÀN APP ---
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: kPrimaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        scaffoldBackgroundColor: Color(0xFFF5F7FA), // Nền xám nhạt hiện đại
        appBarTheme: AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
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

      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/thankyou': (context) => ThankYouScreen(),
        '/admin': (context) => AdminDashboard(),
        '/staff': (context) => StaffDashboard(), // Đã thêm staff
        '/doctor': (context) => DoctorDashboard(),

        // Doctor Sub-screens
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
