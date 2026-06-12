import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_strategy/url_strategy.dart';
import 'providers/auth_provider.dart';
import 'services/socket_service.dart';
import 'router.dart';

const Color kPrimaryColor = Color(0xFF1565C0);

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  // Wrap with ProviderScope — required for all Riverpod providers.
  runApp(const ProviderScope(child: MyApp()));
}

/// Root application widget.
///
/// Uses [ConsumerWidget] so it can watch [authProvider] and automatically
/// manage the [SocketService] connection lifecycle based on auth state.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state — reconnects socket on login, disconnects on logout.
    final auth = ref.watch(authProvider);
    if (auth.isAuthenticated) {
      SocketService.instance.connect(
        token: auth.token!,
        userId: auth.userId ?? '',
        role: auth.role.value,
      );
    } else if (!auth.isLoading) {
      SocketService.instance.disconnect();
    }
    // Thay đổi MaterialApp thành MaterialApp.router
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Smart Clinic - Đặt lịch khám bệnh',

      // Kết nối với cấu hình GoRouter
      routerConfig: router,

      // Giữ nguyên Theme của bạn
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: kPrimaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
    );
  }
}
