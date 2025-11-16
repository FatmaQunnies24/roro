import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../service/player_service.dart';
import '../service/team_service.dart';
import '../model/user_model.dart';
import '../model/player_model.dart';
import '../model/team_model.dart';

class AddUserView extends StatefulWidget {
  const AddUserView({super.key});

  @override
  State<AddUserView> createState() => _AddUserViewState();
}

class _AddUserViewState extends State<AddUserView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teamIdController = TextEditingController();
  final _playerIdController = TextEditingController();

  String _selectedRole = 'coach';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _teamIdController.text = 'team01'; // قيمة افتراضية
  }

  // إنشاء معرف تلقائي بناءً على الاسم والرول
  String _generateUserId(String name, String role) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final namePart = name.replaceAll(' ', '').toLowerCase().substring(0, name.length > 5 ? 5 : name.length);
    final rolePrefix = role == 'coach' ? 'coach' : role == 'player' ? 'player' : 'admin';
    return '${rolePrefix}_${namePart}_$timestamp';
  }

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userService = UserService();

        // إنشاء معرف تلقائي
        String userId = _generateUserId(_nameController.text.trim(), _selectedRole);
        
        // التأكد من أن المعرف غير مستخدم (في حالة التكرار)
        int attempts = 0;
        while (await userService.getUserById(userId) != null && attempts < 10) {
          userId = _generateUserId(_nameController.text.trim(), _selectedRole);
          attempts++;
        }

        // إنشاء المستخدم
        final user = UserModel(
          id: userId,
          name: _nameController.text.trim(),
          role: _selectedRole,
          teamId: _teamIdController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          password: _passwordController.text,
          playerId: _selectedRole == 'player' && _playerIdController.text.trim().isNotEmpty
              ? _playerIdController.text.trim()
              : null,
        );

        await userService.addUser(user);

        // إذا كان لاعب، تأكد من وجود لاعب في قاعدة البيانات
        if (_selectedRole == 'player' && _playerIdController.text.trim().isNotEmpty) {
          final playerService = PlayerService();
          try {
            final player = await playerService.getPlayerById(_playerIdController.text.trim()).first;
            // اللاعب موجود
          } catch (e) {
            // اللاعب غير موجود - يمكن إضافة رسالة تحذير
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("تم إضافة المستخدم، لكن اللاعب غير موجود في قاعدة البيانات"),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم إضافة المستخدم بنجاح"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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
        title: const Text("إضافة مستخدم جديد"),
        backgroundColor: Colors.purple[700],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // المعلومات الأساسية
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "المعلومات الأساسية",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "الاسم *",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "يرجى إدخال الاسم";
                          }
                          return null;
                        },
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
                          if (value.length < 4) {
                            return "كلمة المرور يجب أن تكون 4 أحرف على الأقل";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: "نوع المستخدم *",
                          prefixIcon: Icon(Icons.people),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('أدمن')),
                          DropdownMenuItem(value: 'coach', child: Text('مدرب')),
                          DropdownMenuItem(value: 'player', child: Text('لاعب')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRole = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<TeamModel>>(
                        stream: TeamService().getAllTeams(),
                        builder: (context, snapshot) {
                          final teams = snapshot.data ?? [];
                          if (teams.isEmpty) {
                            return TextFormField(
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
                            );
                          }

                          String? selectedTeamId;
                          if (_teamIdController.text.isNotEmpty && 
                              teams.any((t) => t.id == _teamIdController.text)) {
                            selectedTeamId = _teamIdController.text;
                          } else {
                            selectedTeamId = teams.first.id;
                            _teamIdController.text = teams.first.id;
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedTeamId,
                            decoration: const InputDecoration(
                              labelText: "الفريق *",
                              prefixIcon: Icon(Icons.group),
                              border: OutlineInputBorder(),
                            ),
                            items: teams.map((team) {
                              return DropdownMenuItem(
                                value: team.id,
                                child: Text("${team.name} (${team.id})"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _teamIdController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "يرجى اختيار الفريق";
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      if (_selectedRole == 'player') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _playerIdController,
                          decoration: const InputDecoration(
                            labelText: "معرف اللاعب",
                            hintText: "معرف اللاعب في قاعدة البيانات",
                            prefixIcon: Icon(Icons.sports_soccer),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // زر الإضافة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                          "إضافة المستخدم",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _teamIdController.dispose();
    _playerIdController.dispose();
    super.dispose();
  }
}


