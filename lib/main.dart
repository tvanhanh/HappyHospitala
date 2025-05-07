import 'package:flutter/material.dart';
import './screens/screen_patient/home_screen.dart';
import 'screens/screen_authencication/login_screen.dart';
import 'screens/screen_patient/thank_screen.dart';
import 'screens/screens_admin/home.dart';
import 'screens/screen_staff/home.dart';
import 'screens/screen_doctor/doctor_home_screen.dart';
import './screens/screen_doctor/appointment_page.dart';
//import './screens/screen_doctor/patient_discussion.dart';
import './screens/screen_doctor/patient_management.dart';
import './screens/screen_doctor/prescription.dart';
import './screens/screen_doctor/classification_results.dart';
import './screens/screen_doctor/consultation.dart';
import './screens/screen_doctor/progress_tracking.dart';

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
        '/doctor': (context) => DoctorDashboard(),
        '/staff': (context) => StaffDashboard(),
        '/appointments': (context) => AppointmentPage(),
        '/prescription': (context) => PrescriptionPage(),
        '/patient-management': (context) => PatientManagementPage(),
        '/classification-results': (context) => ClassificationResultsPage(),
        '/consultation': (context) => ConsultationPage(),
        '/progress-tracking': (context) => ProgressTrackingPage(),
        // '/patient-discussion': (context) => PatientDiscussionPage(),
      },
    );
  }
}
