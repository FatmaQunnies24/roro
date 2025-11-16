import 'package:flutter/material.dart';
import 'admin_main_content_view.dart';
import 'add_user_view.dart';
import 'login_view.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة الأدمن"),
        backgroundColor: Colors.purple[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddUserView(),
                ),
              );
            },
            tooltip: "إضافة مستخدم جديد",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
            tooltip: "تسجيل الخروج",
          ),
        ],
      ),
      body: AdminMainContentView(currentIndex: _currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "الرئيسية",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports),
            label: "اللاعبين",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "المدربين",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: "الأدمن",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "الفرق",
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تسجيل الخروج"),
        content: const Text("هل أنت متأكد من تسجيل الخروج؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("تسجيل الخروج"),
          ),
        ],
      ),
    );
  }
}
