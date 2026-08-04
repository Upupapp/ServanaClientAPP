// ignore_for_file: invalid_annotation_target

// ignore: depend_on_referenced_packages
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'user_session.freezed.dart';
part 'user_session.g.dart';

@HiveType(typeId: 5)
@freezed
class UserSession with _$UserSession {
  const factory UserSession({
    @HiveField(51) required String customerID,
    @HiveField(52) required String mobileNumber,
    @HiveField(53) String? referralCode,
    @HiveField(54) required String fullname,
    @HiveField(56) String? emailAddress,
    @Default('') @HiveField(58) String token,

    /// Buys a new [token] when it expires.
    ///
    /// [token] is a Firebase ID token and lives ONE HOUR — the backend validates
    /// it with admin.auth().verifyIdToken(). Social sign-in can renew via the
    /// Firebase SDK, but email/password sign-in happens SERVER-side, so
    /// FirebaseAuth.currentUser is null on this device and there is nothing for
    /// the SDK to refresh. Those sessions redeem this at POST /api/auth/refresh.
    ///
    /// NULLABLE on purpose. A non-nullable field with a default generates
    /// `fields[59] as String` in the Hive adapter, which throws
    /// "Null is not a subtype of String" for every session persisted BEFORE
    /// this field existed — i.e. every currently signed-in user. The code
    /// compiles and new-session tests pass; only real devices with existing
    /// data break, on cold start, after release.
    @HiveField(59) String? refreshToken,
  }) = _UserSession;

  const UserSession._();

  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);
}
