/// Socket.IO connection service for real-time features.
///
/// Provides a singleton-pattern service that manages the WebSocket connection
/// to the Node.js backend using the `socket_io_client` package.
///
/// **Features supported via real-time events:**
/// - New appointment notifications (→ Receptionist, Doctor)
/// - Appointment status changes (→ Patient)
/// - Low stock alerts (→ Pharmacy)
/// - Payment confirmations (→ Cashier, Patient)
/// - Doctor availability updates (→ Receptionist)
///
/// **Architecture:**
/// [SocketService] is a singleton initialized in `main.dart` after login.
/// It emits events when the [AuthNotifier] confirms authentication,
/// and disconnects on logout.
///
/// **Lifecycle:**
/// ```
/// App Start → connect() with JWT in auth header
///     → emit 'join_room' with role + userId
///     → listen for events
/// Logout → disconnect()
/// App Pause → auto-managed by socket_io_client
/// ```
library;

import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/config.dart';

/// Singleton Socket.IO service for Smart Clinic real-time communication.
///
/// Usage:
/// ```dart
/// // Initialize once after login (e.g., in AuthNotifier or main.dart)
/// final socket = SocketService.instance;
/// socket.connect(token: 'Bearer eyJ...', userId: '123', role: 'doctor');
///
/// // Listen for notifications in any widget's initState
/// socket.on(SocketEvents.newNotification, (data) {
///   print('New notification: $data');
/// });
///
/// // Emit an event
/// socket.emit(SocketEvents.joinRoom, {'room': 'doctor_123'});
///
/// // Clean up on screen dispose
/// socket.off(SocketEvents.newNotification);
///
/// // Logout
/// socket.disconnect();
/// ```
class SocketService {
  // ══════════════════════════════════════════════════════════════════════════
  // SINGLETON PATTERN
  // ══════════════════════════════════════════════════════════════════════════

  /// The single shared instance of [SocketService].
  static final SocketService instance = SocketService._internal();

  /// Private constructor for singleton pattern.
  SocketService._internal();

  // ══════════════════════════════════════════════════════════════════════════
  // FIELDS
  // ══════════════════════════════════════════════════════════════════════════

  /// The underlying socket_io_client socket instance.
  io.Socket? _socket;

  /// Returns true when the socket is connected and ready to emit/receive.
  bool get isConnected => _socket?.connected ?? false;

  // ══════════════════════════════════════════════════════════════════════════
  // CONNECTION MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  /// Establishes the Socket.IO connection to the Node.js backend.
  ///
  /// This method is idempotent — calling it multiple times will not create
  /// duplicate connections. If already connected, it will return immediately.
  ///
  /// The JWT [token] is sent in the `auth` handshake header, allowing the
  /// backend to authenticate the WebSocket connection using the same
  /// middleware as REST API calls.
  ///
  /// After connection is established, automatically emits [SocketEvents.joinRoom]
  /// to subscribe to role-based notification channels.
  ///
  /// Parameters:
  /// - [token]: The raw JWT (e.g., from [AuthState.token])
  /// - [userId]: The logged-in user's MongoDB ObjectId
  /// - [role]: The user's role string (e.g., 'doctor', 'receptionist')
  void connect({
    required String token,
    required String userId,
    required String role,
  }) {
    // Guard: skip if already connected.
    if (isConnected) return;

    _socket = io.io(
      // Connect to the Socket.IO endpoint on the Node.js backend.
      // The base URL is shared with REST API calls via config.dart.
      baseUrl,
      io.OptionBuilder()
          // Use WebSocket transport for lowest latency.
          .setTransports(['websocket'])
          // Automatically attempt reconnection on disconnect.
          .enableReconnection()
          // Wait 2s between reconnection attempts (avoid hammering the server).
          .setReconnectionDelay(2000)
          // Give up after 10 failed reconnection attempts.
          .setReconnectionAttempts(10)
          // Send JWT in the Socket.IO auth handshake.
          // Backend can access via: socket.handshake.auth.token
          .setAuth({'token': token})
          // Additional query params for quick access without JWT decode.
          .setQuery({'userId': userId, 'role': role})
          .build(),
    );

    _registerCoreListeners(userId: userId, role: role);
  }

  /// Disconnects from the Socket.IO server and clears the socket instance.
  ///
  /// Called by [AuthNotifier.logout] to clean up the real-time connection.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CORE LIFECYCLE LISTENERS (Internal)
  // ══════════════════════════════════════════════════════════════════════════

  /// Registers the essential connection lifecycle event handlers.
  void _registerCoreListeners({
    required String userId,
    required String role,
  }) {
    _socket!

      // ── Connection established ─────────────────────────────────────────
      ..on('connect', (_) {
        print('[SocketService] ✅ Connected | ID: ${_socket!.id}');
        // Join role-based notification room after connection.
        // Backend routes events to specific rooms (e.g., 'doctor', 'cashier').
        _socket!.emit(SocketEvents.joinRoom, {
          'userId': userId,
          'role': role,
          'roomId': '${role}_room',
        });
      })

      // ── Connection error ───────────────────────────────────────────────
      ..on('connect_error', (error) {
        print('[SocketService] ❌ Connection error: $error');
      })

      // ── Disconnected (either manually or server-side) ──────────────────
      ..on('disconnect', (reason) {
        print('[SocketService] 🔌 Disconnected: $reason');
      })

      // ── Reconnection attempt ───────────────────────────────────────────
      ..on('reconnect_attempt', (attempt) {
        print('[SocketService] 🔄 Reconnecting... attempt #$attempt');
      })

      // ── Reconnection succeeded ─────────────────────────────────────────
      ..on('reconnect', (_) {
        print('[SocketService] ✅ Reconnected successfully');
        // Re-join room after reconnect as the server may have lost state.
        _socket!.emit(SocketEvents.joinRoom, {
          'userId': userId,
          'role': role,
          'roomId': '${role}_room',
        });
      });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EVENT API (Public)
  // ══════════════════════════════════════════════════════════════════════════

  /// Registers a callback for the given [event] name.
  ///
  /// Use [SocketEvents] constants for event names to avoid typos.
  ///
  /// Example:
  /// ```dart
  /// SocketService.instance.on(SocketEvents.newNotification, (data) {
  ///   setState(() => _notifications.add(data));
  /// });
  /// ```
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Removes a specific callback previously registered with [on].
  ///
  /// Call this in your widget's `dispose()` to prevent memory leaks.
  void off(String event) {
    _socket?.off(event);
  }

  /// Emits an event to the server with an optional [data] payload.
  ///
  /// Example:
  /// ```dart
  /// SocketService.instance.emit(SocketEvents.appointmentUpdated, {
  ///   'appointmentId': '123',
  ///   'status': 'confirmed',
  /// });
  /// ```
  void emit(String event, [dynamic data]) {
    if (!isConnected) {
      print('[SocketService] ⚠️ Cannot emit "$event" — not connected');
      return;
    }
    _socket!.emit(event, data);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EVENT NAME CONSTANTS
// ══════════════════════════════════════════════════════════════════════════════

/// Centralizes all Socket.IO event name strings.
///
/// Using constants prevents typos in event names across multiple screens.
/// Both server and client must use matching event names.
///
/// Server-side event names should match these exactly in Node.js:
/// ```js
/// io.to('doctor_room').emit(SocketEvents.newNotification, data);
/// ```
abstract class SocketEvents {
  // ── Room management ──────────────────────────────────────────────────────
  /// Client → Server: Join a notification room after connection.
  static const String joinRoom = 'join_room';

  /// Client → Server: Leave a room (e.g., on logout).
  static const String leaveRoom = 'leave_room';

  // ── Notifications ────────────────────────────────────────────────────────
  /// Server → Client: A new in-app notification arrived.
  static const String newNotification = 'new_notification';

  // ── Appointments ─────────────────────────────────────────────────────────
  /// Server → Client: A new appointment was booked.
  static const String newAppointment = 'new_appointment';

  /// Server → Client: An existing appointment's status changed.
  static const String appointmentStatusChanged = 'appointment_status_changed';

  /// Client → Server: Confirm that an appointment update was received.
  static const String appointmentUpdated = 'appointment_updated';

  // ── Pharmacy / Inventory ─────────────────────────────────────────────────
  /// Server → Client: Drug stock has fallen below minimum threshold.
  static const String lowStockAlert = 'low_stock_alert';

  /// Server → Client: A prescription is ready to be dispensed.
  static const String prescriptionReady = 'prescription_ready';

  // ── Cashier / Payment ────────────────────────────────────────────────────
  /// Server → Client: Payment for an invoice was confirmed.
  static const String paymentConfirmed = 'payment_confirmed';

  /// Server → Client: New invoice created, awaiting cashier processing.
  static const String newInvoice = 'new_invoice';
}
