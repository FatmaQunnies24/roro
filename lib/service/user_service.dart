import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

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

  /// البحث عن مستخدم بالبريد الإلكتروني
  Future<UserModel?> findUserByEmail(String email) async {
    try {
      final snapshot = await _usersRef
          .where('email', isEqualTo: email)
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

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<UserModel?> login(String email, String password) async {
    final user = await findUserByEmail(email);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  /// إضافة مستخدم جديد
  Future<void> addUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toMap());
  }

  /// تحديث معلومات المستخدم
  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.id).update(user.toMap());
  }

  /// حذف مستخدم
  Future<void> deleteUser(String userId) async {
    await _usersRef.doc(userId).delete();
  }
}

