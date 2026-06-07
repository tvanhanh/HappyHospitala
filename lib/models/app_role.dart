/// Defines the canonical set of user roles supported by the Smart Clinic system.
///
/// This enum is the single source of truth for role-based access control (RBAC)
/// across all Flutter screens. It mirrors the `role` enum defined in
/// `backend/models/User.ts` and the ERD Use Case diagram.
///
/// Usage:
/// ```dart
/// final role = AppRole.fromString(prefs.getString('role'));
/// if (role == AppRole.doctor) { /* show doctor UI */ }
/// ```
enum AppRole {
  /// Standard patient who books appointments, views records, uses AI prediction.
  patient,

  /// Licensed medical practitioner who conducts examinations and creates medical records.
  doctor,

  /// System administrator with full access to user management and settings.
  admin,

  /// Financial staff responsible for billing, invoice generation, and payments.
  cashier,

  /// Front-desk staff who manage check-ins, appointment scheduling, and notifications.
  receptionist,

  /// Pharmacy staff who dispense medicine and manage inventory.
  pharmacy,

  /// Fallback for unknown or unrecognized role strings.
  unknown;

  /// Converts a raw role [String] from the JWT/API response into an [AppRole].
  ///
  /// This is the safe way to parse the role stored in [SharedPreferences].
  /// Returns [AppRole.unknown] for any unrecognized value rather than throwing.
  static AppRole fromString(String? roleStr) {
    switch (roleStr?.toLowerCase().trim()) {
      case 'patient':
        return AppRole.patient;
      case 'doctor':
        return AppRole.doctor;
      case 'admin':
        return AppRole.admin;
      case 'cashier':
        return AppRole.cashier;
      case 'receptionist':
        return AppRole.receptionist;
      // Legacy 'staff' value maps to receptionist for backward compatibility
      case 'staff':
        return AppRole.receptionist;
      case 'pharmacy':
        return AppRole.pharmacy;
      default:
        return AppRole.unknown;
    }
  }

  /// Returns the raw string value as stored in the database.
  /// Note: [AppRole.unknown] returns 'patient' as a safe fallback.
  String get value {
    switch (this) {
      case AppRole.patient:
        return 'patient';
      case AppRole.doctor:
        return 'doctor';
      case AppRole.admin:
        return 'admin';
      case AppRole.cashier:
        return 'cashier';
      case AppRole.receptionist:
        return 'receptionist';
      case AppRole.pharmacy:
        return 'pharmacy';
      case AppRole.unknown:
        return 'patient';
    }
  }

  /// Human-readable Vietnamese display name for UI labels.
  String get displayName {
    switch (this) {
      case AppRole.patient:
        return 'Bệnh nhân';
      case AppRole.doctor:
        return 'Bác sĩ';
      case AppRole.admin:
        return 'Quản trị viên';
      case AppRole.cashier:
        return 'Thu ngân';
      case AppRole.receptionist:
        return 'Lễ tân';
      case AppRole.pharmacy:
        return 'Dược sĩ';
      case AppRole.unknown:
        return 'Không xác định';
    }
  }

  /// Returns the GoRouter initial route for this role after successful login.
  ///
  /// Called by [SplashScreen] and the login handler to redirect the user
  /// to the correct dashboard based on their role.
  String get initialRoute {
    switch (this) {
      case AppRole.patient:
        return '/home';
      case AppRole.doctor:
        return '/doctor';
      case AppRole.admin:
        return '/admin';
      case AppRole.cashier:
        return '/cashier';
      case AppRole.receptionist:
        return '/receptionist/dashboard';
      case AppRole.pharmacy:
        return '/pharmacy';
      case AppRole.unknown:
        return '/auth/login';
    }
  }
}
