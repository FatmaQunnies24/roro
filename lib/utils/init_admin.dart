import '../service/user_service.dart';
import '../model/user_model.dart';

/// تهيئة المستخدم الأدمن fatma
/// استدعِ هذه الدالة مرة واحدة لإنشاء حساب الأدمن
Future<void> initializeAdmin() async {
  final userService = UserService();

  // التحقق من وجود الأدمن
  final existingAdmin = await userService.getUserById('fatma');
  if (existingAdmin != null) {
    print('المستخدم الأدمن fatma موجود بالفعل');
    return;
  }

  // إنشاء المستخدم الأدمن
  final admin = UserModel(
    id: 'fatma',
    name: 'Fatma',
    role: 'admin',
    teamId: 'admin', // قيمة افتراضية للأدمن
    email: 'fatima.n.qunnies@gmail.com',
    password: 'admin123', // يمكن تغييرها لاحقاً
  );

  await userService.addUser(admin);
  print('تم إنشاء المستخدم الأدمن fatma بنجاح');
  print('البريد الإلكتروني: fatima.n.qunnies@gmail.com');
  print('كلمة المرور: admin123');
}

