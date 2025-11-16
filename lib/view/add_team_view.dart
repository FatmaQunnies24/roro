import 'package:flutter/material.dart';
import '../service/team_service.dart';
import '../model/team_model.dart';

class AddTeamView extends StatefulWidget {
  const AddTeamView({super.key});

  @override
  State<AddTeamView> createState() => _AddTeamViewState();
}

class _AddTeamViewState extends State<AddTeamView> {
  final _formKey = GlobalKey<FormState>();
  final _teamIdController = TextEditingController();
  final _teamNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addTeam() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final teamService = TeamService();

        // التحقق من أن المعرف غير مستخدم
        final existingTeam = await teamService.getTeamById(_teamIdController.text.trim());
        if (existingTeam != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("معرف الفريق مستخدم بالفعل"),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // إنشاء الفريق
        final team = TeamModel(
          id: _teamIdController.text.trim(),
          name: _teamNameController.text.trim(),
          playersCount: 0,
          coachesCount: 0,
        );

        await teamService.addTeam(team);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم إنشاء الفريق بنجاح"),
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
        title: const Text("إضافة فريق جديد"),
        backgroundColor: Colors.purple[700],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.group,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                "إنشاء فريق جديد",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _teamIdController,
                decoration: const InputDecoration(
                  labelText: "معرف الفريق *",
                  hintText: "مثال: team01",
                  prefixIcon: Icon(Icons.badge),
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
                controller: _teamNameController,
                decoration: const InputDecoration(
                  labelText: "اسم الفريق *",
                  hintText: "مثال: فريق النجمة",
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "يرجى إدخال اسم الفريق";
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _addTeam(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addTeam,
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
                          "إنشاء الفريق",
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
    _teamIdController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }
}


