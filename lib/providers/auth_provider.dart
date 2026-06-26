
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../models/app_role.dart';
import '../services/api_service.dart';
import 'auth_state.dart';

/// The global Riverpod provider for authentication state.
///
/// Wrap your [MaterialApp] with [ProviderScope] (done in `main.dart`) to
/// make this provider available throughout the widget tree.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Manages the authentication lifecycle: startup restore, login, logout.
///
/// Extends [StateNotifier<AuthState>] which Riverpod watches for changes.
/// All state mutations go through `state = ...` which triggers widget rebuilds.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Initializes with [AuthState.initial] (loading) and immediately attempts
  /// to restore a session from [SharedPreferences].
  AuthNotifier() : super(const AuthState.initial()) {
    _restoreSession();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SESSION RESTORE
  // ══════════════════════════════════════════════════════════════════════════

  /// Attempts to restore a persisted JWT session from [SharedPreferences].
  ///
  /// Called automatically on app startup. If a valid, non-expired token is
  /// found, the user is silently logged in. Otherwise, transitions to the
  /// unauthenticated state so the router can redirect to `/login`.
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        state = const AuthState.unauthenticated();
        return;
      }

      // Verify the JWT has not expired on the client side before using it.
      if (JwtDecoder.isExpired(token)) {
        await _clearPrefs(prefs);
        state = const AuthState.unauthenticated();
        return;
      }

      // Restore all cached session fields.
      state = AuthState(
        token: token,
        role: AppRole.fromString(prefs.getString('role')),
        userId: prefs.getString('userId'),
        name: prefs.getString('name'),
        email: prefs.getString('email'),
        avatarUrl: prefs.getString('avatarUrl'),
        isLoading: false,
      );
    } catch (e) {
      // On any error, fail safely to the unauthenticated state.
      state = const AuthState.unauthenticated();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGIN
  // ══════════════════════════════════════════════════════════════════════════

  /// Authenticates the user with the backend `/auth/login` endpoint.
  ///
  /// On success, persists the session to [SharedPreferences] and updates
  /// [state] so all listening widgets automatically rebuild.
  ///
  /// Returns `null` on success, or an error message [String] on failure.
  /// The UI should display the error message to the user.
  ///
  /// Example:
  /// ```dart
  /// final error = await ref.read(authProvider.notifier).login(email, pass);
  /// if (error != null) showSnackBar(error);
  /// ```
  Future<String?> login(String email, String password) async {
    // Set loading to block UI interactions during the request.
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await ApiService.loginUser(email, password);

      if (result.containsKey('error')) {
        final errorMsg = result['error'] as String;
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        return errorMsg;
      }

      // Login succeeded — extract user data from the API response.
      final user = result['user'] as Map<String, dynamic>? ?? {};
      final token = result['token'] as String? ?? '';
      final roleStr = user['role']?.toString() ?? '';
      final role = AppRole.fromString(roleStr);
      final profile = user['profile'] as Map<String, dynamic>? ?? {};

      final avatarVal =
          profile['avatar']?.toString() ?? user['avatar']?.toString() ?? '';
      final specialtyVal = profile['specialty']?.toString() ?? '';

      final newState = AuthState(
        token: token,
        role: role,
        userId: user['_id']?.toString(),
        name: user['name']?.toString(),
        email: user['email']?.toString(),
        avatarUrl: avatarVal.isNotEmpty ? avatarVal : null,
        isLoading: false,
      );

      // Persist all session fields for [_restoreSession] on next app launch.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', role.value);
      await prefs.setString('userId', user['_id']?.toString() ?? '');
      await prefs.setString('doctorId', user['_id']?.toString() ?? '');
      await prefs.setString('name', user['name']?.toString() ?? '');
      await prefs.setString('email', user['email']?.toString() ?? '');
      await prefs.setString('avatarUrl', avatarVal);
      await prefs.setString('avatar', avatarVal);
      await prefs.setString('specialty', specialtyVal);

      state = newState;
      return null; // null = success
    } catch (e) {
      final errorMsg = 'Connection error: $e';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return errorMsg;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GOOGLE LOGIN
  // ══════════════════════════════════════════════════════════════════════════

  Future<String?> loginWithGoogle(String idToken) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await ApiService.googleLoginUser(idToken);

      if (result.containsKey('error')) {
        final errorMsg = result['error'] as String;
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        return errorMsg;
      }

      final user = result['user'] as Map<String, dynamic>? ?? {};
      final token = result['token'] as String? ?? '';
      final roleStr = user['role']?.toString() ?? '';
      final role = AppRole.fromString(roleStr);

      final avatarVal = user['avatar']?.toString() ?? '';

      final newState = AuthState(
        token: token,
        role: role,
        userId: user['_id']?.toString() ?? user['id']?.toString(),
        name: user['name']?.toString() ?? user['fullName']?.toString(),
        email: user['email']?.toString(),
        avatarUrl: avatarVal.isNotEmpty ? avatarVal : null,
        isLoading: false,
      );

      state = newState;
      return null;
    } catch (e) {
      final errorMsg = 'Connection error: $e';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return errorMsg;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════════════════════

  /// Clears the session: wipes [SharedPreferences] and resets [state] to
  /// [AuthState.unauthenticated], triggering a redirect to `/login`.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearPrefs(prefs);
    state = const AuthState.unauthenticated();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE UPDATE
  // ══════════════════════════════════════════════════════════════════════════

  /// Updates the locally cached display name and avatar without a full re-login.
  ///
  /// Called after the user successfully updates their profile.
  void updateLocalProfile({String? name, String? avatarUrl}) {
    state = state.copyWith(
      name: name ?? state.name,
      avatarUrl: avatarUrl ?? state.avatarUrl,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Removes all session-related keys from [SharedPreferences].
  Future<void> _clearPrefs(SharedPreferences prefs) async {
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('doctorId');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('avatarUrl');
    await prefs.remove('specialty');
  }
}
