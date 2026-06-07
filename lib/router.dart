// ignore_for_file: duplicate_import
import 'package:flutter/material.dart';
import 'package:flutter_application_datlichkham/models/appointment.dart';
import 'package:flutter_application_datlichkham/screens/screen_authencication/splash_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/medical_record_detail_page.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/appointment_detail_screen_doctor.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/appointment_detail_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/booking_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/discussion_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/doctor_list_patient.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/patient_appointments_screen.dart';
import 'package:flutter_application_datlichkham/models/patient.dart';
import 'package:flutter_application_datlichkham/screens/screen_patient/update_profile_screen.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/AddDoctorScreen.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/add_doctor_info.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/doctor_list.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/manage_price.dart';
import 'package:flutter_application_datlichkham/screens/screens_admin/security_screens/security_ayth.dart';
import 'package:flutter_application_datlichkham/screens/screens_common/doctor_detail_screen.dart';
import 'package:flutter_application_datlichkham/screens/screen_doctor/medical_record_page.dart';
import 'package:go_router/go_router.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────
import 'screens/screen_authencication/login_screen.dart';
import 'screens/screen_authencication/change_password_screen.dart';
import 'screens/screen_authencication/change_password_page.dart';
import 'screens/screen_authencication/confirmation_screen.dart';
import 'screens/screen_authencication/forgot_password_screen.dart';
import 'screens/screen_authencication/register_screen.dart';

// ── Patient ───────────────────────────────────────────────────────────────────
import 'screens/screen_patient/home_screen.dart';
import 'screens/screen_patient/home_shell.dart';
import 'screens/screen_patient/chat_screen.dart';
import 'screens/screen_patient/thank_screen.dart';
import 'screens/screen_patient/profile_screen.dart';
import 'screens/screen_patient/diagnosis_result_screen.dart';
import 'screens/screen_patient/specialties_screen.dart';
import 'screens/screen_patient/medical_facilities_screen.dart';
import 'screens/screen_patient/faq_screen.dart';
import 'screens/screen_patient/medical_records.dart';
import 'screens/screen_patient/book_appointment_screen.dart';
import 'screens/screen_patient/select_room_screen.dart';
import 'screens/screen_patient/select_doctor_screen.dart';

// ── Admin ─────────────────────────────────────────────────────────────────────
import 'screens/screens_admin/admin_dashboard.dart';
import 'screens/screens_admin/patient_detail.dart';
import 'screens/screens_admin/security_screens/create_account_screen.dart';

// ── Receptionist ──────────────────────────────────────────────────────
import 'screens/screen_receptionist/appointment_management_screen.dart';
import 'screens/screen_receptionist/dashboard.dart';
import 'screens/screen_receptionist/patient_management_screen.dart';
import 'screens/screen_receptionist/notificationScreen.dart';
import 'screens/screen_receptionist/medical_records_screen.dart';

// ── Doctor ────────────────────────────────────────────────────────────────────
import 'screens/screen_doctor/doctor_home_screen.dart';
import 'screens/screen_doctor/appointment_page.dart';
import 'screens/screen_doctor/patient_management.dart';
import 'screens/screen_doctor/prescription.dart';
import 'screens/screen_doctor/classification_results.dart';
import 'screens/screen_doctor/consultation.dart';
import 'screens/screen_doctor/progress_tracking.dart';
import 'screens/screen_doctor/chatAI_screen.dart';
import 'screens/screen_doctor/medical_record_formblockchain.dart';
import 'screens/screen_doctor/list_medical_record.dart';
import 'screens/screen_doctor/appointment_detail_screen_doctor.dart';
import 'screens/screen_doctor/doctor_profile_screen.dart';

// ── Cashier ────────────────────────────────────────────────────────────────
import 'screens/screen_cashier/cashier_dashboard.dart';

// ── Pharmacy ───────────────────────────────────────────────────────────────
import 'screens/screen_pharmacy/pharmacy_dashboard.dart';

/// The application's top-level [GoRouter] configuration.
///
/// Navigation is role-based:
/// - `/` → Splash (auto-redirects based on stored JWT role)
/// - `/home/**` and `/patient/**` → Patient shell with bottom navigation
/// - `/doctor/**` → Doctor dashboard
/// - `/admin/**` → Admin dashboard
/// - `/receptionist/**` → Receptionist dashboard
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // ── PUBLIC & AUTH ──────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => LoginScreen(),
      routes: [
        GoRoute(path: 'login', builder: (context, state) => LoginScreen()),
        GoRoute(
            path: 'register', builder: (context, state) => RegisterScreen()),
        GoRoute(
            path: 'forgot_password',
            builder: (context, state) => ForgotPasswordScreen()),
        GoRoute(
            path: 'change_password_reset',
            builder: (context, state) => const ChangePasswordScreen()),
        GoRoute(
          path: 'change_password_page',
          builder: (context, state) {
            final email = state.extra as String? ?? '';
            return ChangePasswordPage(email: email);
          },
        ),
      ],
    ),
    GoRoute(
        path: '/update_profile',
        builder: (context, state) => UpdateProfileScreen()),

    // ── PATIENT ───────────────────────────────────────────────────
    GoRoute(path: '/thankyou', builder: (context, state) => ThankYouScreen()),
    GoRoute(
        path: '/patient_apointment',
        builder: (context, state) => PatientAppointmentsScreen()),
    GoRoute(
      path: '/patient-detail',
      builder: (context, state) {
        final patientData = (state.extra as Map<String, dynamic>?) ?? {};
        return PatientDetailScreen(patient: patientData);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
                path: 'profile', builder: (context, state) => ProfileScreen()),
            GoRoute(
                path: 'discussion',
                builder: (context, state) => DiscussionScreen()),
            GoRoute(
              path: 'appointments',
              builder: (context, state) => PatientAppointmentsScreen(),
              routes: [
                GoRoute(
                  path: 'appointment-detail',
                  builder: (context, state) {
                    final appointment = state.extra as Appointment?;
                    if (appointment == null) {
                      return Scaffold(
                        body: Center(
                            child: Text(
                                'Appointment data missing for appointment detail.')),
                      );
                    }
                    return AppointmentDetailScreen(appointment: appointment);
                  },
                ),
              ],
            ),
            GoRoute(
                path: 'results',
                builder: (context, state) => DiagnosisResultScreen()),
          ],
        ),
        GoRoute(
          path: '/patient',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
                path: 'doctor_list',
                builder: (context, state) => PatientDoctorListScreen()),
            GoRoute(
                path: 'book-appointment',
                builder: (context, state) => const BookAppointmentScreen(),
                routes: [
                  GoRoute(
                    path: 'rooms/:specialtyId',
                    builder: (context, state) {
                      final specialtyId = state.pathParameters['specialtyId']!;
                      return SelectRoomScreen(specialtyId: specialtyId);
                    },
                    routes: [
                      GoRoute(
                        path: 'doctors/:roomId',
                        builder: (context, state) {
                          final roomId = state.pathParameters['roomId']!;
                          return SelectDoctorScreen(roomId: roomId);
                        },
                      ),
                    ],
                  ),
                ]),
            GoRoute(
                path: 'specialties_screen',
                builder: (context, state) => SpecialtiesScreen()),
            GoRoute(
                path: 'medical_facilities_screen',
                builder: (context, state) => MedicalFacilitiesScreen()),
            GoRoute(
                path: 'medical-records',
                builder: (context, state) => MedicalRecordsPage()),
            GoRoute(
                path: 'appointments',
                builder: (context, state) => PatientAppointmentsScreen()),
            GoRoute(
                path: 'profile-screen',
                builder: (context, state) => ProfileScreen()),
            GoRoute(
                path: 'diagnosis_result_screen',
                builder: (context, state) => DiagnosisResultScreen()),
            GoRoute(path: 'faq', builder: (context, state) => FAQScreen()),
            GoRoute(
                path: 'chat',
                builder: (context, state) => const ChatListScreen()),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/medical-record',
      builder: (context, state) {
        final patient = state.extra as Patient?;
        if (patient == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Bệnh án không tìm thấy'),
            ),
            body: const Center(
              child: Text(
                  'Không tìm thấy thông tin bệnh nhân để hiển thị bệnh án.'),
            ),
          );
        }
        return MedicalRecordPage(patient: patient);
      },
    ),

    // ── ADMIN ─────────────────────────────────────────────────────
    GoRoute(
      path: '/admin',
      builder: (context, state) => AdminDashboard(),
      routes: [
        GoRoute(
            path: 'user_management',
            builder: (context, state) => UserManagementScreen()),
        GoRoute(
            path: 'create_account',
            builder: (context, state) => CreateUserScreenState()),
        GoRoute(
            path: 'add-doctor', builder: (context, state) => AddDoctorScreen()),
        GoRoute(
            path: 'doctor-list',
            builder: (context, state) => DoctorListScreen()),
        GoRoute(
            path: 'manage-price',
            builder: (context, state) => ManagePriceScreen()),
      ],
    ),

    // ── DOCTOR ────────────────────────────────────────────────────
    GoRoute(
      path: '/doctor',
      builder: (context, state) => DoctorDashboard(),
      routes: [
        GoRoute(
          path: 'appointments',
          builder: (context, state) => DoctorAppointmentsScreen(),
          routes: [
            GoRoute(
              path: 'appointment-detail',
              builder: (context, state) {
                final appointment = state.extra as Appointment?;
                if (appointment == null) {
                  return Scaffold(
                    body: Center(
                        child: Text(
                            'Appointment data missing for doctor appointment detail.')),
                  );
                }
                return AppointmentDetailDoctorScreen(appointment: appointment);
              },
            ),
          ],
        ),
        GoRoute(
            path: 'profile',
            builder: (context, state) => DoctorProfileScreen()),
        GoRoute(
            path: 'edit/:doctorId',
            builder: (context, state) => AddDoctorInfoScreen(
                doctorId: state.pathParameters['doctorId']!)),
        GoRoute(
          path: 'create-medical-record',
          builder: (context, state) {
            final appointment = state.extra as Appointment?;
            if (appointment == null) {
              return Scaffold(
                body: Center(
                    child: Text(
                        'Appointment is required to create a medical record.')),
              );
            }
            return MedicalRecordForm(appointment: appointment);
          },
        ),
        GoRoute(
            path: 'list-medical',
            builder: (context, state) => MedicalRecordListPage()),
        GoRoute(
            path: 'addMedicalRecord',
            builder: (context, state) => MedicalRecordsPage()),
        GoRoute(
            path: 'medical-records',
            builder: (context, state) => const MedicalRecordsScreen(showAppBar: true, showDrawer: false)),
      ],
    ),
    GoRoute(
        path: '/diagnosis', builder: (context, state) => DiagnosisFormScreen()),

    // ── RECEPTIONIST & STAFF ─────────────────────────────────────
    GoRoute(
      path: '/receptionist',
      builder: (context, state) => const ReceptionistDashboard(),
      routes: [
        GoRoute(
            path: 'dashboard',
            builder: (context, state) => const ReceptionistDashboard()),
        GoRoute(
            path: 'patient-management',
            builder: (context, state) => const PatientManagementScreen()),
        GoRoute(
            path: 'appointment-management',
            builder: (context, state) =>
                const ReceptionistDashboardScreen()),
        GoRoute(
            path: 'notification',
            builder: (context, state) => const NotificationScreen()),
        GoRoute(
            path: 'medical-records',
            builder: (context, state) => const MedicalRecordsScreen()),
      ],
    ),
    GoRoute(
        path: '/staff',
        builder: (context, state) => const ReceptionistDashboard()),

    // ── CASHIER & PHARMACY ─────────────────────────────────────
    GoRoute(
        path: '/cashier',
        builder: (context, state) => const CashierDashboard()),
    GoRoute(
        path: '/pharmacy',
        builder: (context, state) => const PharmacyDashboard()),

    // ── SHARED ───────────────────────────────────────────────────
    GoRoute(
        path: '/medical-record-detail/:recordId',
        builder: (context, state) => MedicalRecordDetailPage(
            recordId: state.pathParameters['recordId']!)),
    GoRoute(
        path: '/prescription', builder: (context, state) => PrescriptionPage()),
    GoRoute(
        path: '/patient-management',
        builder: (context, state) => PatientManagementPage()),
    GoRoute(
        path: '/classification-results',
        builder: (context, state) => ClassificationResultsPage()),
    GoRoute(
        path: '/consultation', builder: (context, state) => ConsultationPage()),
    GoRoute(
        path: '/progress-tracking',
        builder: (context, state) => ProgressTrackingPage()),
    GoRoute(
      path: '/doctor-detail/:id',
      builder: (context, state) => DoctorDetailScreen(
        doctorId: state.pathParameters['id']!,
        role: 'patient',
      ),
    ),
    GoRoute(
      path: '/booking/:doctorId',
      builder: (context, state) =>
          BookingScreen(doctorId: state.pathParameters['doctorId']!),
    ),
  ],
);
