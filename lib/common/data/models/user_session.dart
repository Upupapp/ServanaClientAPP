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
    @HiveField(57) String? password,
    @Default('') @HiveField(58) String token,
  }) = _UserSession;

  const UserSession._();

  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);
}
