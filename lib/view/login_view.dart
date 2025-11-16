import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../model/user_model.dart';
import 'coach_home_view.dart';
import 'player_home_view.dart';
import 'admin_home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userService = UserService();
        final user = await userService.login(
          _userIdController.text.trim(),
          _passwordController.text,
        );

        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("المستخدم غير موجود أو كلمة المرور غير صحيحة"),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // توجيه المستخدم حسب نوعه
        if (mounted) {
          final role = user.role.toLowerCase();
          if (role == 'admin' || role == 'أدمن') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AdminHomeView(),
              ),
            );
          } else if (role == 'coach' || role == 'مدرب') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CoachHomeView(teamId: user.teamId),
              ),
            );
          } else if (role == 'player' || role == 'لاعب') {
            if (user.playerId != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerHomeView(playerId: user.playerId!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("معرف اللاعب غير موجود"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("نوع المستخدم غير معروف"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("حدث خطأ: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تسجيل الدخول"),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_soccer,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 40),
                const Text(
                  "تطبيق كرة القدم",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: "معرف المستخدم أو البريد الإلكتروني",
                    hintText: "أدخل المعرف أو البريد الإلكتروني",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى إدخال المعرف أو البريد الإلكتروني";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "كلمة المرور",
                    hintText: "أدخل كلمة المرور",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى إدخال كلمة المرور";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "تسجيل الدخول",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "ملاحظة: استخدم معرف المستخدم أو البريد الإلكتروني مع كلمة المرور",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
