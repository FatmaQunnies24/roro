import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../service/player_service.dart';
import '../model/user_model.dart';
import '../model/player_model.dart';
import '../utils/player_metrics_calculator.dart';
import 'player_home_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _teamIdController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _teamIdController.text = 'team01'; // قيمة افتراضية
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      // التحقق من تطابق كلمة المرور
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("كلمة المرور غير متطابقة"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final userService = UserService();
        final playerService = PlayerService();

        // التحقق من أن المعرف غير مستخدم
        final existingUser = await userService.getUserById(_userIdController.text.trim());
        if (existingUser != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("المعرف مستخدم بالفعل، يرجى اختيار معرف آخر"),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // التحقق من أن البريد الإلكتروني غير مستخدم
        if (_emailController.text.trim().isNotEmpty) {
          final existingEmail = await userService.findUserByEmailOrId(_emailController.text.trim());
          if (existingEmail != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("البريد الإلكتروني مستخدم بالفعل"),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
        }

        // إنشاء معرف فريد للاعب
        final playerId = 'player_${_userIdController.text.trim()}';

        // إنشاء لاعب جديد بقيم افتراضية
        final defaultPlayer = PlayerModel(
          id: playerId,
          name: _nameController.text.trim(),
          teamId: _teamIdController.text.trim(),
          positionType: 'substitute', // افتراضي: احتياطي
          roleInTeam: 'reserve', // افتراضي: احتياطي
          speed: 15.0, // قيمة افتراضية
          shotPower: 2000.0, // قيمة افتراضية
          stamina: 50.0, // قيمة افتراضية
          bodyStrength: 100.0, // قيمة افتراضية
          balance: 50.0, // قيمة افتراضية
          effortIndex: 50.0, // قيمة افتراضية
        );

        // إضافة اللاعب إلى قاعدة البيانات بمعرف محدد
        await playerService.addPlayerWithId(defaultPlayer);

        // إنشاء المستخدم
        final user = UserModel(
          id: _userIdController.text.trim(),
          name: _nameController.text.trim(),
          role: 'player', // دائماً لاعب عند التسجيل
          teamId: _teamIdController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          password: _passwordController.text,
          playerId: playerId, // ربط المستخدم باللاعب
        );

        // إضافة المستخدم إلى قاعدة البيانات
        await userService.addUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم إنشاء الحساب بنجاح!"),
              backgroundColor: Colors.green,
            ),
          );

          // توجيه المستخدم إلى صفحة اللاعب
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerHomeView(playerId: playerId),
            ),
          );
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
        title: const Text("إنشاء حساب جديد"),
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
                  Icons.person_add,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  "إنشاء حساب لاعب جديد",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "الاسم الكامل *",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى إدخال الاسم";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: "معرف المستخدم *",
                    hintText: "مثال: player123",
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى إدخال معرف المستخدم";
                    }
                    if (value.length < 3) {
                      return "المعرف يجب أن يكون 3 أحرف على الأقل";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "البريد الإلكتروني",
                    hintText: "example@email.com",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _teamIdController,
                  decoration: const InputDecoration(
                    labelText: "معرف الفريق *",
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى إدخال معرف الفريق";
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
                    labelText: "كلمة المرور *",
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
                    if (value.length < 6) {
                      return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "تأكيد كلمة المرور *",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى تأكيد كلمة المرور";
                    }
                    if (value != _passwordController.text) {
                      return "كلمة المرور غير متطابقة";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signUp(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
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
                            "إنشاء الحساب",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "لديك حساب بالفعل؟ تسجيل الدخول",
                    style: TextStyle(fontSize: 16),
                  ),
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
    _nameController.dispose();
    _emailController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teamIdController.dispose();
    super.dispose();
  }
}

