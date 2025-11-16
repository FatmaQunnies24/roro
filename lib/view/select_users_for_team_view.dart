import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../service/team_service.dart';
import '../model/user_model.dart';

class SelectUsersForTeamView extends StatefulWidget {
  final String teamId;
  final String role; // 'player' or 'coach'

  const SelectUsersForTeamView({
    super.key,
    required this.teamId,
    required this.role,
  });

  @override
  State<SelectUsersForTeamView> createState() => _SelectUsersForTeamViewState();
}

class _SelectUsersForTeamViewState extends State<SelectUsersForTeamView> {
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;

  Future<void> _addSelectedUsers() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى اختيار مستخدم واحد على الأقل"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      final teamService = TeamService();

      // تحديث teamId لكل مستخدم مختار
      for (final userId in _selectedUserIds) {
        final user = await userService.getUserById(userId);
        if (user != null) {
          final updatedUser = UserModel(
            id: user.id,
            name: user.name,
            role: user.role,
            teamId: widget.teamId,
            email: user.email,
            password: user.password,
            playerId: user.playerId,
          );
          await userService.updateUser(updatedUser);
        }
      }

      // تحديث عدد المستخدمين في الفريق
      await teamService.updateTeamCounts(widget.teamId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم إضافة ${_selectedUserIds.length} ${widget.role == 'coach' ? 'مدرب' : 'لاعب'} بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // إرجاع true للإشارة إلى التحديث
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("اختر ${widget.role == 'coach' ? 'مدربين' : 'لاعبين'}"),
        backgroundColor: widget.role == 'coach' ? Colors.blue[700] : Colors.green[700],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: UserService().getUsersByRole(widget.role),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("لا يوجد ${widget.role == 'coach' ? 'مدربين' : 'لاعبين'} متاحين"),
            );
          }

          final allUsers = snapshot.data!;
          // تصفية المستخدمين غير الموجودين في هذا الفريق
          final availableUsers = allUsers.where((user) => user.teamId != widget.teamId).toList();

          if (availableUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "جميع ${widget.role == 'coach' ? 'المدربين' : 'اللاعبين'} موجودين بالفعل في هذا الفريق",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // شريط المعلومات
              Container(
                padding: const EdgeInsets.all(16),
                color: widget.role == 'coach' ? Colors.blue[50] : Colors.green[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "تم اختيار: ${_selectedUserIds.length}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedUserIds.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedUserIds.clear());
                        },
                        child: const Text("إلغاء الكل"),
                      ),
                  ],
                ),
              ),

              // قائمة المستخدمين
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = availableUsers[index];
                    final isSelected = _selectedUserIds.contains(user.id);
                    final currentTeam = user.teamId.isNotEmpty ? user.teamId : 'لا يوجد';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected
                          ? (widget.role == 'coach' ? Colors.blue[100] : Colors.green[100])
                          : null,
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUserIds.add(user.id);
                            } else {
                              _selectedUserIds.remove(user.id);
                            }
                          });
                        },
                        title: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("المعرف: ${user.id}"),
                            if (user.email != null) Text("البريد: ${user.email}"),
                            Text("الفريق الحالي: $currentTeam"),
                          ],
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? (widget.role == 'coach' ? Colors.blue : Colors.green)
                              : Colors.grey,
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // زر التم
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addSelectedUsers,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isLoading ? "جاري الإضافة..." : "تم",
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.role == 'coach' ? Colors.blue[700] : Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


