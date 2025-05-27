import 'package:flutter/material.dart';
import 'router.dart'; 
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
   usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
   
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router, // cấu hình go_router ở đây
      debugShowCheckedModeBanner: false,
      title: 'Đặt lịch khám bệnh',
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
