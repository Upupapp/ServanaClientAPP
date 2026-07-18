// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'merchant_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MerchantUser _$MerchantUserFromJson(Map<String, dynamic> json) {
  return _MerchantUser.fromJson(json);
}

/// @nodoc
mixin _$MerchantUser {
  String get merchantUserID => throw _privateConstructorUsedError;
  int get merchantUserRoleType => throw _privateConstructorUsedError;
  int? get jobOrderPersonnelID => throw _privateConstructorUsedError;
  String get contactNumber => throw _privateConstructorUsedError;
  int get merchantUserStatus => throw _privateConstructorUsedError;
  String get profilePictureURL => throw _privateConstructorUsedError;
  String get fullname => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MerchantUserCopyWith<MerchantUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MerchantUserCopyWith<$Res> {
  factory $MerchantUserCopyWith(
          MerchantUser value, $Res Function(MerchantUser) then) =
      _$MerchantUserCopyWithImpl<$Res, MerchantUser>;
  @useResult
  $Res call(
      {String merchantUserID,
      int merchantUserRoleType,
      int? jobOrderPersonnelID,
      String contactNumber,
      int merchantUserStatus,
      String profilePictureURL,
      String fullname});
}

/// @nodoc
class _$MerchantUserCopyWithImpl<$Res, $Val extends MerchantUser>
    implements $MerchantUserCopyWith<$Res> {
  _$MerchantUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantUserID = null,
    Object? merchantUserRoleType = null,
    Object? jobOrderPersonnelID = freezed,
    Object? contactNumber = null,
    Object? merchantUserStatus = null,
    Object? profilePictureURL = null,
    Object? fullname = null,
  }) {
    return _then(_value.copyWith(
      merchantUserID: null == merchantUserID
          ? _value.merchantUserID
          : merchantUserID // ignore: cast_nullable_to_non_nullable
              as String,
      merchantUserRoleType: null == merchantUserRoleType
          ? _value.merchantUserRoleType
          : merchantUserRoleType // ignore: cast_nullable_to_non_nullable
              as int,
      jobOrderPersonnelID: freezed == jobOrderPersonnelID
          ? _value.jobOrderPersonnelID
          : jobOrderPersonnelID // ignore: cast_nullable_to_non_nullable
              as int?,
      contactNumber: null == contactNumber
          ? _value.contactNumber
          : contactNumber // ignore: cast_nullable_to_non_nullable
              as String,
      merchantUserStatus: null == merchantUserStatus
          ? _value.merchantUserStatus
          : merchantUserStatus // ignore: cast_nullable_to_non_nullable
              as int,
      profilePictureURL: null == profilePictureURL
          ? _value.profilePictureURL
          : profilePictureURL // ignore: cast_nullable_to_non_nullable
              as String,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MerchantUserImplCopyWith<$Res>
    implements $MerchantUserCopyWith<$Res> {
  factory _$$MerchantUserImplCopyWith(
          _$MerchantUserImpl value, $Res Function(_$MerchantUserImpl) then) =
      __$$MerchantUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String merchantUserID,
      int merchantUserRoleType,
      int? jobOrderPersonnelID,
      String contactNumber,
      int merchantUserStatus,
      String profilePictureURL,
      String fullname});
}

/// @nodoc
class __$$MerchantUserImplCopyWithImpl<$Res>
    extends _$MerchantUserCopyWithImpl<$Res, _$MerchantUserImpl>
    implements _$$MerchantUserImplCopyWith<$Res> {
  __$$MerchantUserImplCopyWithImpl(
      _$MerchantUserImpl _value, $Res Function(_$MerchantUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantUserID = null,
    Object? merchantUserRoleType = null,
    Object? jobOrderPersonnelID = freezed,
    Object? contactNumber = null,
    Object? merchantUserStatus = null,
    Object? profilePictureURL = null,
    Object? fullname = null,
  }) {
    return _then(_$MerchantUserImpl(
      merchantUserID: null == merchantUserID
          ? _value.merchantUserID
          : merchantUserID // ignore: cast_nullable_to_non_nullable
              as String,
      merchantUserRoleType: null == merchantUserRoleType
          ? _value.merchantUserRoleType
          : merchantUserRoleType // ignore: cast_nullable_to_non_nullable
              as int,
      jobOrderPersonnelID: freezed == jobOrderPersonnelID
          ? _value.jobOrderPersonnelID
          : jobOrderPersonnelID // ignore: cast_nullable_to_non_nullable
              as int?,
      contactNumber: null == contactNumber
          ? _value.contactNumber
          : contactNumber // ignore: cast_nullable_to_non_nullable
              as String,
      merchantUserStatus: null == merchantUserStatus
          ? _value.merchantUserStatus
          : merchantUserStatus // ignore: cast_nullable_to_non_nullable
              as int,
      profilePictureURL: null == profilePictureURL
          ? _value.profilePictureURL
          : profilePictureURL // ignore: cast_nullable_to_non_nullable
              as String,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MerchantUserImpl implements _MerchantUser {
  const _$MerchantUserImpl(
      {required this.merchantUserID,
      required this.merchantUserRoleType,
      this.jobOrderPersonnelID,
      required this.contactNumber,
      required this.merchantUserStatus,
      required this.profilePictureURL,
      required this.fullname});

  factory _$MerchantUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$MerchantUserImplFromJson(json);

  @override
  final String merchantUserID;
  @override
  final int merchantUserRoleType;
  @override
  final int? jobOrderPersonnelID;
  @override
  final String contactNumber;
  @override
  final int merchantUserStatus;
  @override
  final String profilePictureURL;
  @override
  final String fullname;

  @override
  String toString() {
    return 'MerchantUser(merchantUserID: $merchantUserID, merchantUserRoleType: $merchantUserRoleType, jobOrderPersonnelID: $jobOrderPersonnelID, contactNumber: $contactNumber, merchantUserStatus: $merchantUserStatus, profilePictureURL: $profilePictureURL, fullname: $fullname)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MerchantUserImpl &&
            (identical(other.merchantUserID, merchantUserID) ||
                other.merchantUserID == merchantUserID) &&
            (identical(other.merchantUserRoleType, merchantUserRoleType) ||
                other.merchantUserRoleType == merchantUserRoleType) &&
            (identical(other.jobOrderPersonnelID, jobOrderPersonnelID) ||
                other.jobOrderPersonnelID == jobOrderPersonnelID) &&
            (identical(other.contactNumber, contactNumber) ||
                other.contactNumber == contactNumber) &&
            (identical(other.merchantUserStatus, merchantUserStatus) ||
                other.merchantUserStatus == merchantUserStatus) &&
            (identical(other.profilePictureURL, profilePictureURL) ||
                other.profilePictureURL == profilePictureURL) &&
            (identical(other.fullname, fullname) ||
                other.fullname == fullname));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      merchantUserID,
      merchantUserRoleType,
      jobOrderPersonnelID,
      contactNumber,
      merchantUserStatus,
      profilePictureURL,
      fullname);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MerchantUserImplCopyWith<_$MerchantUserImpl> get copyWith =>
      __$$MerchantUserImplCopyWithImpl<_$MerchantUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MerchantUserImplToJson(
      this,
    );
  }
}

abstract class _MerchantUser implements MerchantUser {
  const factory _MerchantUser(
      {required final String merchantUserID,
      required final int merchantUserRoleType,
      final int? jobOrderPersonnelID,
      required final String contactNumber,
      required final int merchantUserStatus,
      required final String profilePictureURL,
      required final String fullname}) = _$MerchantUserImpl;

  factory _MerchantUser.fromJson(Map<String, dynamic> json) =
      _$MerchantUserImpl.fromJson;

  @override
  String get merchantUserID;
  @override
  int get merchantUserRoleType;
  @override
  int? get jobOrderPersonnelID;
  @override
  String get contactNumber;
  @override
  int get merchantUserStatus;
  @override
  String get profilePictureURL;
  @override
  String get fullname;
  @override
  @JsonKey(ignore: true)
  _$$MerchantUserImplCopyWith<_$MerchantUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
