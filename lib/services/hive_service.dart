import 'package:hive/hive.dart';
import '../models/user_model.dart';

class HiveService {
  static const String _boxName = 'userBox';
  static const String _userKey = 'currentUser';

  Future<Box> get _box async => await Hive.openBox(_boxName);

  Future<void> saveUser(UserModel user) async {
    final box = await _box;
    await box.put(_userKey, user.toJson());
  }

  Future<UserModel?> getUser() async {
    final box = await _box;
    final userData = box.get(_userKey);
    if (userData != null) {
      return UserModel.fromJson(Map<String, dynamic>.from(userData));
    }
    return null;
  }

  Future<void> clearUser() async {
    final box = await _box;
    await box.delete(_userKey);
  }
} 