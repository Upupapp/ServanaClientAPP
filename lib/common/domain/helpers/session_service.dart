import 'package:hive/hive.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:flutter/foundation.dart';

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
    // An unreadable session store means "not signed in", never an exception.
    //
    // This was unguarded, and 22 call sites across the API client, the booking
    // stores, the address repository and the auth bloc all assumed it could
    // not throw. It can: opening a Hive box hits the disk, and the cast can
    // fail if the persisted adapter shape ever changes. On 2026-08-11 exactly
    // that propagated out of the API client and every category screen told
    // customers to "check your connection" over a local storage fault.
    //
    // caa768b guarded the API client — one of the twenty-two. Guarding here
    // covers the rest, and null is the honest answer: if the session cannot be
    // read, the customer is not signed in as far as this process can tell.
    try {
      final hive = HiveHelper();
      var box = await hive.openBox("session");
      var user = box.get("user") as UserSession?;

      return user;
    } catch (e) {
      debugPrint(
          '[SessionService] session unreadable, treating as signed out: $e');
      return null;
    }
  }
}
