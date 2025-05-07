import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/thank_screen.dart';
import 'screens/screens_admin/home.dart';
import 'screens/screen_doctor/home.dart';
import 'screens/screen_staff/home.dart';
import 'screens/screen_doctor/doctor_home_screen.dart';
import './screens/screen_doctor/appointment_page.dart';
import './screens/screen_doctor/patient_discussion_page.dart';
import './screens/screen_doctor/patient_management_page.dart';
import './screens/screen_doctor/prescription_page.dart';
import './screens/screen_doctor/classification_results_page.dart';
import './screens/screen_doctor/consultation_page.dart';
import './screens/screen_doctor/progress_tracking_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Đặt lịch khám bệnh',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Định nghĩa route ban đầu là '/'
      routes: {
        // Thêm màn hình chính vào '/'
        '/home': (context) => HomeScreen(),
        '/thankyou': (context) => ThankYouScreen(),
        '/': (context) => LoginScreen(),
        '/admin': (context) => AdminDashboard(),
        '/doctor': (context) => DoctorHomePage(),
        '/staff': (context) => StaffDashboard(),
        '/appointments': (context) => AppointmentPage(),
        '/prescription': (context) => PrescriptionPage(),
        '/patient-management': (context) => PatientManagementPage(),
        '/classification-results': (context) => ClassificationResultsPage(),
        '/consultation': (context) => ConsultationPage(),
        '/progress-tracking': (context) => ProgressTrackingPage(),
        '/patient-discussion': (context) => PatientDiscussionPage(),
      },
    );
  }
}
