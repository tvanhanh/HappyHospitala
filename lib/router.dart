import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/screen_authencication/login_screen.dart';
import 'screens/screen_patient/home_screen.dart';
import 'screens/screen_patient/thank_screen.dart';
import 'screens/screens_admin/home.dart';
import 'screens/screen_staff/home.dart';
import 'screens/screen_doctor/doctor_home_screen.dart';
import 'screens/screen_doctor/appointment_page.dart';
import 'screens/screen_doctor/patient_management.dart';
import 'screens/screen_doctor/prescription.dart';
import 'screens/screen_doctor/classification_results.dart';
import 'screens/screen_doctor/consultation.dart';
import 'screens/screen_doctor/progress_tracking.dart';
import 'screens/screen_authencication/register_screen.dart';
import 'screens/screen_patient/booking_screen.dart';
import 'screens/screen_doctor/medical_record_formblockchain.dart';

final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/thankyou',
      builder: (context, state) => ThankYouScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => AdminDashboard(),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => StaffDashboard(),
    ),
    GoRoute(
      path: '/doctor',
      builder: (context, state) => DoctorDashboard(),
    ),
    GoRoute(
      path: '/appointments',
      builder: (context, state) => AppointmentPage(),
    ),
    GoRoute(
      path: '/prescription',
      builder: (context, state) => PrescriptionPage(),
    ),
    GoRoute(
      path: '/patient-management',
      builder: (context, state) => PatientManagementPage(),
    ),
    GoRoute(
      path: '/classification-results',
      builder: (context, state) => ClassificationResultsPage(),
    ),
    GoRoute(
      path: '/consultation',
      builder: (context, state) => ConsultationPage(),
    ),
    GoRoute(
      path: '/progress-tracking',
      builder: (context, state) => ProgressTrackingPage(),
    ),
    GoRoute(
      path: '/home/booking',
      builder: (context, state) => BookingScreen(),
    ),
    GoRoute(
      path: '/doctor/medical-record',
      builder: (context, state) => MedicalRecordForm(),
    ),
  ],
);
