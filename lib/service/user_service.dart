import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';
import 'team_service.dart';

class UserService {
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  /// جلب معلومات المستخدم حسب المعرف
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// البحث عن مستخدم بالبريد الإلكتروني أو المعرف
  Future<UserModel?> findUserByEmailOrId(String emailOrId) async {
    try {
      // البحث بالمعرف أولاً
      final doc = await _usersRef.doc(emailOrId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }

      // البحث بالبريد الإلكتروني
      final snapshot = await _usersRef
          .where('email', isEqualTo: emailOrId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return UserModel.fromMap(doc.id, doc.data());
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// التحقق من كلمة المرور
  Future<bool> verifyPassword(UserModel user, String password) async {
    return user.password == password;
  }

  /// تسجيل الدخول بالبريد/المعرف وكلمة المرور
  Future<UserModel?> login(String emailOrId, String password) async {
    final user = await findUserByEmailOrId(emailOrId);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  /// إضافة مستخدم جديد
  Future<void> addUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toMap());
    
    // تحديث عدد المستخدمين في الفريق
    try {
      final teamService = TeamService();
      await teamService.updateTeamCounts(user.teamId);
    } catch (e) {
      // تجاهل الخطأ إذا كان الفريق غير موجود
      print('خطأ في تحديث عدد المستخدمين: $e');
    }
  }

  /// تحديث معلومات المستخدم
  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.id).update(user.toMap());
  }

  /// جلب جميع المستخدمين
  Stream<List<UserModel>> getAllUsers() {
    return _usersRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// جلب المستخدمين حسب الرول
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _usersRef
        .where('role', isEqualTo: role)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// حذف مستخدم
  Future<void> deleteUser(String userId) async {
    await _usersRef.doc(userId).delete();
  }
}

