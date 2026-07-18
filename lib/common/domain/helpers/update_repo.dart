import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateHelper {
  static Future<void> checkForUpdateAndroid() async {
    var res = await InAppUpdate.checkForUpdate();
    if (res.updateAvailability == UpdateAvailability.updateAvailable) {
      await InAppUpdate.performImmediateUpdate();
    }
  }

  static Future<void> checkForUpdate() async {
    if (Platform.isAndroid) {
      try {
        await checkForUpdateAndroid();
      } catch (e) {
        FirebaseCrashlytics.instance.log(e.toString());
      }
    }
    if (Platform.isIOS) {
      ///todo implement iOS updater
    }
  }
}
