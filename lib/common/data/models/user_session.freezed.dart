// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserSession _$UserSessionFromJson(Map<String, dynamic> json) {
  return _UserSession.fromJson(json);
}

/// @nodoc
mixin _$UserSession {
  @HiveField(51)
  String get customerID => throw _privateConstructorUsedError;
  @HiveField(52)
  String get mobileNumber => throw _privateConstructorUsedError;
  @HiveField(53)
  String? get referralCode => throw _privateConstructorUsedError;
  @HiveField(54)
  String get fullname => throw _privateConstructorUsedError;
  @HiveField(56)
  String? get emailAddress => throw _privateConstructorUsedError;
  @HiveField(58)
  String get token => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSessionCopyWith<UserSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSessionCopyWith<$Res> {
  factory $UserSessionCopyWith(
          UserSession value, $Res Function(UserSession) then) =
      _$UserSessionCopyWithImpl<$Res, UserSession>;
  @useResult
  $Res call(
      {@HiveField(51) String customerID,
      @HiveField(52) String mobileNumber,
      @HiveField(53) String? referralCode,
      @HiveField(54) String fullname,
      @HiveField(56) String? emailAddress,
      @HiveField(58) String token});
}

/// @nodoc
class _$UserSessionCopyWithImpl<$Res, $Val extends UserSession>
    implements $UserSessionCopyWith<$Res> {
  _$UserSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerID = null,
    Object? mobileNumber = null,
    Object? referralCode = freezed,
    Object? fullname = null,
    Object? emailAddress = freezed,
    Object? token = null,
  }) {
    return _then(_value.copyWith(
      customerID: null == customerID
          ? _value.customerID
          : customerID // ignore: cast_nullable_to_non_nullable
              as String,
      mobileNumber: null == mobileNumber
          ? _value.mobileNumber
          : mobileNumber // ignore: cast_nullable_to_non_nullable
              as String,
      referralCode: freezed == referralCode
          ? _value.referralCode
          : referralCode // ignore: cast_nullable_to_non_nullable
              as String?,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
      emailAddress: freezed == emailAddress
          ? _value.emailAddress
          : emailAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSessionImplCopyWith<$Res>
    implements $UserSessionCopyWith<$Res> {
  factory _$$UserSessionImplCopyWith(
          _$UserSessionImpl value, $Res Function(_$UserSessionImpl) then) =
      __$$UserSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(51) String customerID,
      @HiveField(52) String mobileNumber,
      @HiveField(53) String? referralCode,
      @HiveField(54) String fullname,
      @HiveField(56) String? emailAddress,
      @HiveField(58) String token});
}

/// @nodoc
class __$$UserSessionImplCopyWithImpl<$Res>
    extends _$UserSessionCopyWithImpl<$Res, _$UserSessionImpl>
    implements _$$UserSessionImplCopyWith<$Res> {
  __$$UserSessionImplCopyWithImpl(
      _$UserSessionImpl _value, $Res Function(_$UserSessionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerID = null,
    Object? mobileNumber = null,
    Object? referralCode = freezed,
    Object? fullname = null,
    Object? emailAddress = freezed,
    Object? token = null,
  }) {
    return _then(_$UserSessionImpl(
      customerID: null == customerID
          ? _value.customerID
          : customerID // ignore: cast_nullable_to_non_nullable
              as String,
      mobileNumber: null == mobileNumber
          ? _value.mobileNumber
          : mobileNumber // ignore: cast_nullable_to_non_nullable
              as String,
      referralCode: freezed == referralCode
          ? _value.referralCode
          : referralCode // ignore: cast_nullable_to_non_nullable
              as String?,
      fullname: null == fullname
          ? _value.fullname
          : fullname // ignore: cast_nullable_to_non_nullable
              as String,
      emailAddress: freezed == emailAddress
          ? _value.emailAddress
          : emailAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSessionImpl extends _UserSession {
  const _$UserSessionImpl(
      {@HiveField(51) required this.customerID,
      @HiveField(52) required this.mobileNumber,
      @HiveField(53) this.referralCode,
      @HiveField(54) required this.fullname,
      @HiveField(56) this.emailAddress,
      @HiveField(58) this.token = ''})
      : super._();

  factory _$UserSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSessionImplFromJson(json);

  @override
  @HiveField(51)
  final String customerID;
  @override
  @HiveField(52)
  final String mobileNumber;
  @override
  @HiveField(53)
  final String? referralCode;
  @override
  @HiveField(54)
  final String fullname;
  @override
  @HiveField(56)
  final String? emailAddress;
  @override
  @JsonKey()
  @HiveField(58)
  final String token;

  @override
  String toString() {
    return 'UserSession(customerID: $customerID, mobileNumber: $mobileNumber, referralCode: $referralCode, fullname: $fullname, emailAddress: $emailAddress, token: $token)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSessionImpl &&
            (identical(other.customerID, customerID) ||
                other.customerID == customerID) &&
            (identical(other.mobileNumber, mobileNumber) ||
                other.mobileNumber == mobileNumber) &&
            (identical(other.referralCode, referralCode) ||
                other.referralCode == referralCode) &&
            (identical(other.fullname, fullname) ||
                other.fullname == fullname) &&
            (identical(other.emailAddress, emailAddress) ||
                other.emailAddress == emailAddress) &&
            (identical(other.token, token) || other.token == token));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, customerID, mobileNumber,
      referralCode, fullname, emailAddress, token);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSessionImplCopyWith<_$UserSessionImpl> get copyWith =>
      __$$UserSessionImplCopyWithImpl<_$UserSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSessionImplToJson(
      this,
    );
  }
}

abstract class _UserSession extends UserSession {
  const factory _UserSession(
      {@HiveField(51) required final String customerID,
      @HiveField(52) required final String mobileNumber,
      @HiveField(53) final String? referralCode,
      @HiveField(54) required final String fullname,
      @HiveField(56) final String? emailAddress,
      @HiveField(58) final String token}) = _$UserSessionImpl;
  const _UserSession._() : super._();

  factory _UserSession.fromJson(Map<String, dynamic> json) =
      _$UserSessionImpl.fromJson;

  @override
  @HiveField(51)
  String get customerID;
  @override
  @HiveField(52)
  String get mobileNumber;
  @override
  @HiveField(53)
  String? get referralCode;
  @override
  @HiveField(54)
  String get fullname;
  @override
  @HiveField(56)
  String? get emailAddress;
  @override
  @HiveField(58)
  String get token;
  @override
  @JsonKey(ignore: true)
  _$$UserSessionImplCopyWith<_$UserSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
