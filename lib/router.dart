import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/models/appointment.dart';
import 'package:flutter_application_datlichkham/screens/screen_authencication/splash_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/medical_record_detail_page.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/appointment_detail_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/booking_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/discussion_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/doctor_list_patient.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/patient_appointments_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/update_profile_screen.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/AddDoctorScreen.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/add_doctor_info.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/doctor_list.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/manage_price.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/security_screens/security_ayth.dart';
import 'package:flutter_application_datlichkham/screens/screens_common/doctor_detail_screen.dart';
import 'package:go_router/go_router.dart';

import 'screens/screen_authencication/login_screen.dart';
import 'screens/screen_authencication/change_password_screen.dart';
import 'screens/screen_authencication/change_password_page.dart';
import 'screens/screen_authencication/confirmation_screen.dart';
import 'screens/screen_authencication/forgot_password_screen.dart';
import 'screens/screen_authencication/register_screen.dart';

import 'screens/screen_patient/home_screen.dart';
import 'screens/screen_patient/home_shell.dart';
import 'screens/screen_patient/thank_screen.dart';
import 'screens/screens_admin/home.dart';
import 'screens/screens_admin/patient_detail.dart';
import 'screens/screens_admin/security_screens/create_account_screen.dart';
import 'screens/screen_staff/home.dart';

import 'screens/screen_doctor/doctor_home_screen.dart';
import 'screens/screen_doctor/appointment_page.dart';
import 'screens/screen_doctor/patient_management.dart';
import 'screens/screen_doctor/prescription.dart';
import 'screens/screen_doctor/classification_results.dart';
import 'screens/screen_doctor/consultation.dart';
import 'screens/screen_doctor/progress_tracking.dart';
import 'screens/screen_doctor/chatAI_screen.dart';

import 'screens/screen_patient/profile_screen.dart';
import 'screens/screen_patient/diagnosis_result_screen.dart';
import 'screens/screen_patient/specialties_screen.dart';

import 'screens/screen_patient/medical_facilities_screen.dart';
import 'screens/screen_patient/faq_screen.dart';
import 'screens/screen_patient/medical_records.dart';
import 'screens/screen_doctor/medical_record_formblockchain.dart';
import 'screens/screen_doctor/list_medical_record.dart';

// Thay bằng đường dẫn thực tế đến file model của bạn

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(),
    ),
    //Authentication
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(),
    ),

    // 3. Màn hình Quên mật khẩu
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordScreen(),
    ),

    // 4. Màn hình Xác nhận (OTP hoặc link xác nhận)

    // 5. Màn hình Đổi mật khẩu (Sau khi quên mật khẩu)
    GoRoute(
      path: '/change-password-reset',
      builder: (context, state) => const ChangePasswordScreen(),
    ),

    // 6. Trang Đổi mật khẩu (Thường dùng trong mục Profile/Cài đặt)
    GoRoute(
      path: '/change-password-page',
      builder: (context, state) {
        // Lấy email từ state.extra và ép kiểu về String
        final email = state.extra as String;
        return ChangePasswordPage(email: email);
      },
    ),
    GoRoute(
      path: '/update_profile',
      builder: (context, state) => UpdateProfileScreen(),
    ),

    //Patient
    GoRoute(
      path: '/doctor_list',
      builder: (context, state) => PatientDoctorListScreen(),
    ),
    GoRoute(
      path: '/thankyou',
      builder: (context, state) => ThankYouScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) {
        return HomeShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          path: '/home/profile',
          builder: (context, state) => ProfileScreen(),
        ),
        GoRoute(
          path: '/home/discussion',
          builder: (context, state) => DiscussionScreen(),
        ),
        GoRoute(
          path: '/home/appointments',
          builder: (context, state) => PatientAppointmentsScreen(),
        ),
        GoRoute(
          path: '/home/results',
          builder: (context, state) => DiagnosisResultScreen(),
        ),
        GoRoute(
          path: '/home/appointments/appointment-detail',
          builder: (context, state) {
            final appointment = state.extra as Appointment;

            return AppointmentDetailScreen(
              appointment: appointment,
            );
          },
        ),
        GoRoute(
          path: '/booking/:doctorId',
          builder: (context, state) => PatientAppointmentsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/patient/profile-screen',
      builder: (context, state) => ProfileScreen(),
    ),
    GoRoute(
        path: '/patient/diagnosis_result_screen',
        builder: (context, state) => DiagnosisResultScreen()),
    GoRoute(
        path: '/patient/specialties_screen',
        builder: (context, state) => SpecialtiesScreen()),
    GoRoute(
        path: '/patient/medical_facilities_screen',
        builder: (context, state) => MedicalFacilitiesScreen()),
    GoRoute(
        path: '/patient/medical-records',
        builder: (context, state) => MedicalRecordsPage()),
    GoRoute(path: '/patient/faq', builder: (context, state) => FAQScreen()),
    GoRoute(
      path: '/patient-detail',
      builder: (context, state) {
        // Ép kiểu state.extra về Map<String, dynamic>
        // Nếu state.extra bị null (do F5), ta tạo một Map trống để tránh lỗi crash
        final patientData = (state.extra as Map<String, dynamic>?) ?? {};

        return PatientDetailScreen(patient: patientData);
      },
    ),
    //Admin
    GoRoute(
      path: '/admin/user_management',
      builder: (context, state) => UserManagementScreen(),
    ),
    GoRoute(
      path: '/admin/add-doctor',
      builder: (context, state) => AddDoctorScreen(),
    ),
    GoRoute(
      path: '/admin/create_account',
      builder: (context, state) => CreateUserScreenState(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => AdminDashboard(),
    ),

    //Staff
    GoRoute(
      path: '/staff',
      builder: (context, state) => StaffDashboard(),
    ),
    //Doctor
    GoRoute(
      path: '/doctor',
      builder: (context, state) => DoctorDashboard(),
    ),
    // GoRoute(
    //   path: '/doctor/addPatient',
    //   builder: (context, state) {
    //     // Ép kiểu state.extra về Map<String, dynamic>
    //     // Nếu state.extra bị null (do F5), ta tạo một Map trống để tránh lỗi crash
    //     final appData = (state.extra as Map<String, dynamic>?) ?? {};

    //     return AppointmentDetailPage(appointment: appData);
    //   },
    // ),
    GoRoute(
        path: '/diagnosis', builder: (context, state) => DiagnosisFormScreen()),
    // GoRoute(
    //   path: '/medical-record',
    //   builder: (context, state) {
    //     // Lấy dữ liệu bệnh nhân từ state.extra
    //     // Ép kiểu (cast) về Map hoặc PatientModel tùy vào cấu trúc của bạn
    //     final patientData = state.extra as Patient;

    //     return MedicalRecordsPage(patient : patientData);
    //   },
    //),

    GoRoute(
      path: '/doctor/edit/:doctorId',
      builder: (context, state) {
        final doctorId = state.pathParameters['doctorId']!;
        return AddDoctorInfoScreen(doctorId: doctorId);
      },
    ),

    GoRoute(
      path: '/patient_apointment',
      builder: (context, state) => PatientAppointmentsScreen(),
    ),

    GoRoute(
      path: '/doctor/appointments',
      builder: (context, state) => DoctorAppointmentsScreen(),
    ),
    GoRoute(
      // :recordId là biến số, nó sẽ thay đổi tùy theo bệnh án bạn chọn
      path: '/medical-record-detail/:recordId',
      builder: (context, state) {
        // Lấy recordId từ URL thanh địa chỉ
        final recordId = state.pathParameters['recordId']!;

        return MedicalRecordDetailPage(recordId: recordId);
      },
    ),
    GoRoute(
      path: '/doctor/create-medical-record',
      builder: (context, state) => const MedicalRecordForm(),
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
      path: '/doctor/create-medical-record',
      builder: (context, state) => MedicalRecordForm(),
    ),

    GoRoute(
      path: '/doctor/list-medical',
      builder: (context, state) => MedicalRecordListPage(),
    ),
    GoRoute(
      path: '/doctor/addMedicalRecord',
      builder: (context, state) => MedicalRecordsPage(),
    ),

    GoRoute(
      path: '/doctor-detail/:id',
      builder: (context, state) {
        final doctorId = state.pathParameters['id']!;

        return DoctorDetailScreen(
          doctorId: doctorId,
          role: "patient", // hoặc lấy từ auth
        );
      },
    ),
    // Department
    // GoRoute(
    //   path: '/admin/manage-price',
    //   builder: (context, state) => const ManagePriceScreen(),
    // ),
  ],
);
