import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../service/user_service.dart';
import '../model/player_model.dart';
import '../model/user_model.dart';

class CoachAssignPlayerPositionView extends StatefulWidget {
  final String userId;
  final String teamId;

  const CoachAssignPlayerPositionView({
    super.key,
    required this.userId,
    required this.teamId,
  });

  @override
  State<CoachAssignPlayerPositionView> createState() => _CoachAssignPlayerPositionViewState();
}

class _CoachAssignPlayerPositionViewState extends State<CoachAssignPlayerPositionView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPosition;
  String? _selectedRole;
  bool _isLoading = false;
  PlayerModel? _playerModel;
  UserModel? _userModel;

  final List<String> _positions = [
    'forward',
    'defender',
    'midfield',
    'goalkeeper',
    'substitute',
  ];

  final List<String> _roles = [
    'starter',
    'reserve',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // جلب بيانات المستخدم
      final userService = UserService();
      final user = await userService.getUserById(widget.userId);
      
      if (user == null || user.playerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("المستخدم غير موجود أو ليس لديه بيانات لاعب"),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _userModel = user;
      });

      // جلب بيانات اللاعب
      final playerService = PlayerService();
      try {
        final player = await playerService.getPlayerById(user.playerId!).first;
        setState(() {
          _playerModel = player;
          _selectedPosition = player.positionType;
          _selectedRole = player.roleInTeam;
        });
      } catch (e) {
        // إذا لم يكن هناك PlayerModel، سننشئ واحد جديد
        setState(() {
          _selectedPosition = 'substitute';
          _selectedRole = 'reserve';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ في تحميل البيانات: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePositionAndRole() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPosition == null || _selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("يرجى اختيار المركز والدور"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final playerService = PlayerService();
        final userService = UserService();

        if (_playerModel == null && _userModel != null && _userModel!.playerId != null) {
          // إنشاء PlayerModel جديد إذا لم يكن موجوداً
          final newPlayer = PlayerModel(
            id: _userModel!.playerId!,
            userId: widget.userId,
            name: _userModel!.name,
            teamId: widget.teamId,
            positionType: _selectedPosition!,
            roleInTeam: _selectedRole!,
            speed: 15.0, // قيم افتراضية
            shotPower: 2000.0,
            stamina: 50.0,
            bodyStrength: 100.0,
            balance: 50.0,
            effortIndex: 50.0,
          );
          await playerService.addPlayerWithId(newPlayer);
        } else if (_playerModel != null) {
          // تحديث PlayerModel الموجود
          final updatedPlayer = PlayerModel(
            id: _playerModel!.id,
            userId: widget.userId,
            name: _playerModel!.name,
            teamId: widget.teamId,
            positionType: _selectedPosition!,
            roleInTeam: _selectedRole!,
            speed: _playerModel!.speed,
            shotPower: _playerModel!.shotPower,
            stamina: _playerModel!.stamina,
            bodyStrength: _playerModel!.bodyStrength,
            balance: _playerModel!.balance,
            effortIndex: _playerModel!.effortIndex,
          );
          await playerService.addPlayerWithId(updatedPlayer);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم حفظ المركز والدور بنجاح"),
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
        title: const Text("تحديد المركز والدور"),
        backgroundColor: Colors.blue[700],
      ),
      body: _userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات المستخدم
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    _userModel!.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userModel!.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("المعرف: ${_userModel!.id}"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // اختيار المركز
                    const Text(
                      "المركز",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPosition,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "اختر المركز",
                      ),
                      items: _positions.map((position) {
                        return DropdownMenuItem(
                          value: position,
                          child: Text(_getPositionArabic(position)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPosition = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return "يرجى اختيار المركز";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // اختيار الدور
                    const Text(
                      "الدور في الفريق",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "اختر الدور",
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(_getRoleArabic(role)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return "يرجى اختيار الدور";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // زر الحفظ
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePositionAndRole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "حفظ",
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

  String _getPositionArabic(String position) {
    switch (position.toLowerCase()) {
      case 'forward':
        return 'هجوم';
      case 'defender':
        return 'دفاع';
      case 'midfield':
        return 'وسط';
      case 'goalkeeper':
        return 'حارس مرمى';
      case 'substitute':
        return 'احتياطي';
      default:
        return position;
    }
  }

  String _getRoleArabic(String role) {
    switch (role.toLowerCase()) {
      case 'starter':
        return 'أساسي';
      case 'reserve':
        return 'احتياطي';
      default:
        return role;
    }
  }
}

