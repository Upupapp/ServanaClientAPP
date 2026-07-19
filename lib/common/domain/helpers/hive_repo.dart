import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/data/models/x_file_mod.dart';
import 'package:client/common/data/models/location_coordinates_model.dart';
import 'package:client/common/domain/helpers/secure_storage_repo.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';

class HiveHelper {
  final secureStorageRepo = SecureStorageHelper();

  Future<Box<T>> openBox<T>(String box) async {
    final key = await secureStorageRepo.retrieveCipherKey();
    if (key == null) {
      throw StateError(
          'Cipher key unavailable — secure storage may be inaccessible.');
    }
    final encryptionKeyUint8List = base64Url.decode(key);
    final cipher = HiveAesCipher(encryptionKeyUint8List);

    try {
      return await Hive.openBox<T>(box, encryptionCipher: cipher);
    } catch (_) {
      // The on-disk box was encrypted with a key we no longer have (e.g. the
      // secure-storage entry was wiped after a BAD_DECRYPT). Drop the corrupted
      // box and reopen with the current cipher so the user can continue.
      try {
        if (Hive.isBoxOpen(box)) {
          await Hive.box<T>(box).close();
        }
      } catch (_) {}
      await Hive.deleteBoxFromDisk(box);
      return await Hive.openBox<T>(box, encryptionCipher: cipher);
    }
  }

  /// registers type adapters for entities
  static void registerAdapters() {
    Hive.registerAdapter(RegistrationFormModelAdapter());
    Hive.registerAdapter(XFileModAdapter());
    Hive.registerAdapter(LocationCoordinatesModelAdapter());
    Hive.registerAdapter(UserSessionAdapter());
  }
}
