import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_user.freezed.dart';
part 'merchant_user.g.dart';

@freezed
class MerchantUser with _$MerchantUser {
  const factory MerchantUser({
    required String merchantUserID,
    required int merchantUserRoleType,
    int? jobOrderPersonnelID,
    required String contactNumber,
    required int merchantUserStatus,
    required String profilePictureURL,
    required String fullname,
  }) = _MerchantUser;

  factory MerchantUser.fromJson(Map<String, dynamic> json) =>
      _$MerchantUserFromJson(json);
}
