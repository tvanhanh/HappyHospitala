/// Defines the shape of the authentication session state.
///
/// This immutable data class is held by [AuthNotifier] and broadcast
/// to all widgets via Riverpod's `ref.watch(authProvider)`.
///
/// State transitions:
/// - App start → [AuthState.initial] (loading = true)
/// - Token found & valid → [AuthState] with populated fields
/// - No token / expired → [AuthState.unauthenticated]
/// - Login success → full [AuthState]
/// - Logout → [AuthState.unauthenticated]
library;

import 'package:flutter_application_datlichkham/models/app_role.dart';

/// Immutable representation of the currently authenticated user session.
class AuthState {
  /// The raw JWT access token returned by the backend `/auth/login` endpoint.
  /// Null if the user is not authenticated.
  final String? token;

  /// The decoded role of the logged-in user.
  /// Defaults to [AppRole.unknown] when unauthenticated.
  final AppRole role;

  /// MongoDB ObjectId string of the logged-in user.
  final String? userId;

  /// Display name of the logged-in user (from `Users.name`).
  final String? name;

  /// Email address of the logged-in user.
  final String? email;

  /// Avatar URL from the user's embedded profile object.
  final String? avatarUrl;

  /// True while the app is restoring session from [SharedPreferences] on startup.
  final bool isLoading;

  /// Non-null when a login or session restore error occurs.
  final String? errorMessage;

  /// Creates an [AuthState].
  const AuthState({
    this.token,
    this.role = AppRole.unknown,
    this.userId,
    this.name,
    this.email,
    this.avatarUrl,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state used while the app checks for a stored token on startup.
  const AuthState.initial()
      : token = null,
        role = AppRole.unknown,
        userId = null,
        name = null,
        email = null,
        avatarUrl = null,
        isLoading = true,
        errorMessage = null;

  /// Unauthenticated state — user is logged out or session has expired.
  const AuthState.unauthenticated()
      : token = null,
        role = AppRole.unknown,
        userId = null,
        name = null,
        email = null,
        avatarUrl = null,
        isLoading = false,
        errorMessage = null;

  /// Returns true when a valid token is present (user is logged in).
  bool get isAuthenticated => token != null && token!.isNotEmpty;

  /// Returns the initial GoRouter route for the current role.
  String get initialRoute => role.initialRoute;

  /// Creates a copy of this state with optionally updated fields.
  AuthState copyWith({
    String? token,
    AppRole? role,
    String? userId,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      token: token ?? this.token,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'AuthState(role: ${role.value}, userId: $userId, '
      'isAuth: $isAuthenticated, loading: $isLoading)';
}
