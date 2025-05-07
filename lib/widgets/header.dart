import 'package:flutter/material.dart';
import '../screens/screen_authencication/login_screen.dart';
import '../screens/screen_authencication/register_screen.dart';
import '../screens/screen_patient/doctors_screen.dart';
import '../screens/screen_patient/faq_screen.dart';
import '../screens/screen_patient/medical_facilities_screen.dart';
import '../screens/screen_patient/specialties_screen.dart';
import '../screens/screen_patient/booking_screen.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final bool isLoggedIn;
  final String userAvatar;

  Header({this.isLoggedIn = false, this.userAvatar = 'assets/avatar.png'});

  @override
  _HeaderState createState() => _HeaderState();

  @override
  Size get preferredSize => Size.fromHeight(60);
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue.shade700,
      elevation: 4,
      title: Row(
        children: [
          Image.asset('assets/logo.png', height: 40),
          SizedBox(width: 20),
          if (MediaQuery.of(context).size.width > 600)
            _buildDesktopMenu(context),
          widget.isLoggedIn
              ? _buildUserAvatar(context)
              : _buildLoginButtons(context),
        ],
      ),
    );
  }

  Widget _buildDesktopMenu(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMenuItem(context, 'Chuyên khoa', SpecialtiesScreen()),
          _buildMenuItem(context, 'Cơ sở y tế', MedicalFacilitiesScreen()),
          _buildMenuItem(context, 'Bác sĩ', DoctorsScreen()),
          _buildMenuItem(context, 'Hỏi đáp', FAQScreen()),
        ],
      ),
    );
  }

  /// **Hover Menu đẹp hơn trên Web**
  Widget _buildMenuItem(BuildContext context, String title, Widget screen) {
    final ValueNotifier<bool> isHovered = ValueNotifier(false);

    return ValueListenableBuilder<bool>(
      valueListenable: isHovered,
      builder: (context, hovered, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => isHovered.value = true,
          onExit: (_) => isHovered.value = false,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screen),
              );
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: hovered
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: hovered ? Colors.yellow : Colors.white,
                  fontWeight: hovered ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// **Hiển thị Avatar nếu đã đăng nhập**
  Widget _buildUserAvatar(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') {
          // Xử lý đăng xuất
        } else if (value == 'change_password') {
          // Điều hướng đổi mật khẩu
        } else if (value == 'forgot_password') {
          // Điều hướng quên mật khẩu
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'change_password', child: Text('Đổi mật khẩu')),
        PopupMenuItem(value: 'forgot_password', child: Text('Quên mật khẩu')),
        PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
      ],
      child: CircleAvatar(
        backgroundImage: AssetImage(widget.userAvatar),
        radius: 22,
      ),
    );
  }

  /// **Nút Đăng nhập / Đăng ký nếu chưa đăng nhập**
  Widget _buildLoginButtons(BuildContext context) {
    return Row(
      children: [
        // ElevatedButton(
        //   onPressed: () => Navigator.push(
        //       context, MaterialPageRoute(builder: (context) => LoginScreen())),
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.white,
        //     foregroundColor: Colors.blue.shade700,
        //   ),
        //   child: Text('Đăng nhập'),
        // ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => RegisterScreen())),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text('Đăng ký'),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => BookingScreen())),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text('Đặt lịch khám'),
        ),
      ],
    );
  }
}
