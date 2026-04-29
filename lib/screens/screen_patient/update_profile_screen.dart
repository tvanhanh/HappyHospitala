import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController phone = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController medicalHistory = TextEditingController();
  final TextEditingController allergies = TextEditingController();
  final TextEditingController chronicDiseases = TextEditingController();
  final TextEditingController skinCondition = TextEditingController();
  final TextEditingController skincareRoutine = TextEditingController();

  String? gender;
  String? skinType;

  bool isLoading = false;

  Future<void> updateProfile() async {
    setState(() => isLoading = true);

    try {
      final data = {
        "profile": {
          "phone": phone.text,
          "gender": gender,
          "address": address.text,
          "medicalHistory": medicalHistory.text,
          "allergies": allergies.text,
          "chronicDiseases": chronicDiseases.text,
          "skinType": skinType,
          "skinCondition": skinCondition.text,
          "skincareRoutine": skincareRoutine.text,
        }
      };

      await ApiService.updateProfile(data);
      final res = await ApiService.getProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật thành công"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        context.go('/home');
      });

      // Điều hướng sau khi update thành công

      // hoặc chuyển về Profile
      // Navigator.pushReplacementNamed(context, '/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cập nhật thất bại: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pop(context);
      });
    }

    setState(() => isLoading = false);
  }

  InputDecoration customInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff4facfe), Color(0xff00f2fe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                buildHeader(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          tabs: [
                            Tab(text: "Cơ bản"),
                            Tab(text: "Bệnh án"),
                            Tab(text: "Da liễu"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              buildBasicTab(),
                              buildMedicalTab(),
                              buildSkinTab(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setState(() => isLoading = true);

                                      try {
                                        final data = {
                                          "profile": {
                                            "phone": phone.text,
                                            "gender": gender,
                                            "address": address.text,
                                            "medicalHistory":
                                                medicalHistory.text,
                                            "allergies": allergies.text,
                                            "chronicDiseases":
                                                chronicDiseases.text,
                                            "skinType": skinType,
                                            "skinCondition": skinCondition.text,
                                            "skincareRoutine":
                                                skincareRoutine.text,
                                          }
                                        };
                                        await ApiService.updateProfile(data);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text("Cập nhật thành công")),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }

                                      setState(() => isLoading = false);
                                    },
                              child: isLoading
                                  ? CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text("Lưu thông tin",
                                      style: TextStyle(fontSize: 18)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Column(
      children: [
        SizedBox(height: 10),
        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, size: 50, color: Colors.grey),
        ),
        SizedBox(height: 10),
        Text("Hồ sơ cá nhân",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Positioned(
          left: 0,
          top: 0,
          child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              }),
        ),
      ],
    );
  }

  Widget buildBasicTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView(
        children: [
          TextField(
              controller: phone,
              decoration: customInput("Số điện thoại", Icons.phone)),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: gender,
            items: ["Nam", "Nữ"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => gender = value),
            decoration: customInput("Giới tính", Icons.person),
          ),
          SizedBox(height: 12),
          TextField(
              controller: address,
              decoration: customInput("Địa chỉ", Icons.location_on)),
        ],
      ),
    );
  }

  Widget buildMedicalTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView(
        children: [
          TextField(
              controller: medicalHistory,
              decoration: customInput("Tiền sử bệnh", Icons.history)),
          SizedBox(height: 12),
          TextField(
              controller: allergies,
              decoration: customInput("Dị ứng", Icons.warning)),
          SizedBox(height: 12),
          TextField(
              controller: chronicDiseases,
              decoration: customInput("Bệnh mãn tính", Icons.local_hospital)),
        ],
      ),
    );
  }

  Widget buildSkinTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView(
        children: [
          DropdownButtonFormField<String>(
            value: skinType,
            items: ["Da dầu", "Da khô", "Da hỗn hợp"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => skinType = value),
            decoration: customInput("Loại da", Icons.face),
          ),
          SizedBox(height: 12),
          TextField(
              controller: skinCondition,
              decoration: customInput("Tình trạng da", Icons.healing)),
          SizedBox(height: 12),
          TextField(
              controller: skincareRoutine,
              decoration: customInput("Routine skincare", Icons.spa)),
        ],
      ),
    );
  }
}
