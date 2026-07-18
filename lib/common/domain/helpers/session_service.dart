import 'package:hive/hive.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';

class SessionService {
//// session

  static Future<void> saveSession(UserSession session) async {
    final hive = HiveHelper();
    var box = await hive.openBox("session");
    await box.put("user", session);
  }

  static Future<void> deleteSession() async {
    try {
      if (Hive.isBoxOpen('session')) {
        await Hive.box('session').close();
      }
    } catch (_) {}
    await Hive.deleteBoxFromDisk('session');
  }

  static Future<UserSession?> getSession() async {
    final hive = HiveHelper();
    var box = await hive.openBox("session");
    var user = box.get("user") as UserSession?;

    return user;
  }
}
