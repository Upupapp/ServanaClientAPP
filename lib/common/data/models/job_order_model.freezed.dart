// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_order_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JobOrder _$JobOrderFromJson(Map<String, dynamic> json) {
  return _JobOrder.fromJson(json);
}

/// @nodoc
mixin _$JobOrder {
  String get jobOrderID => throw _privateConstructorUsedError;
  String get jobOrderNumber => throw _privateConstructorUsedError;
  String get merchantName => throw _privateConstructorUsedError;
  DateTime get scheduleDate => throw _privateConstructorUsedError;
  DateTime? get dateStart => throw _privateConstructorUsedError;
  DateTime? get dateEnd => throw _privateConstructorUsedError;
  @JsonKey(fromJson: intToJobStatus)
  JobOrderStatus get jobOrderStatus => throw _privateConstructorUsedError;
  String get jobOrderStatusToString => throw _privateConstructorUsedError;
  String get merchantID => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  int get numberOfPersonnel => throw _privateConstructorUsedError;
  int get distanceFromOffice => throw _privateConstructorUsedError;
  String get merchantServiceName => throw _privateConstructorUsedError;
  String get merchantServicePhoto => throw _privateConstructorUsedError;
  DateTime? get actualDateStart => throw _privateConstructorUsedError;
  DateTime? get actualDateEnd => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  double get downPayment => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  int get paymentType => throw _privateConstructorUsedError;
  DateTime? get viewDate => throw _privateConstructorUsedError;
  String? get cancelledBy => throw _privateConstructorUsedError;
  DateTime get createdDate => throw _privateConstructorUsedError;
  String? get paymentStatus => throw _privateConstructorUsedError;
  String? get paymentMethodUsed => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $JobOrderCopyWith<JobOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobOrderCopyWith<$Res> {
  factory $JobOrderCopyWith(JobOrder value, $Res Function(JobOrder) then) =
      _$JobOrderCopyWithImpl<$Res, JobOrder>;
  @useResult
  $Res call(
      {String jobOrderID,
      String jobOrderNumber,
      String merchantName,
      DateTime scheduleDate,
      DateTime? dateStart,
      DateTime? dateEnd,
      @JsonKey(fromJson: intToJobStatus) JobOrderStatus jobOrderStatus,
      String jobOrderStatusToString,
      String merchantID,
      String address,
      int numberOfPersonnel,
      int distanceFromOffice,
      String merchantServiceName,
      String merchantServicePhoto,
      DateTime? actualDateStart,
      DateTime? actualDateEnd,
      double latitude,
      double longitude,
      String? note,
      double downPayment,
      double totalAmount,
      int paymentType,
      DateTime? viewDate,
      String? cancelledBy,
      DateTime createdDate,
      String? paymentStatus,
      String? paymentMethodUsed});
}

/// @nodoc
class _$JobOrderCopyWithImpl<$Res, $Val extends JobOrder>
    implements $JobOrderCopyWith<$Res> {
  _$JobOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobOrderID = null,
    Object? jobOrderNumber = null,
    Object? merchantName = null,
    Object? scheduleDate = null,
    Object? dateStart = freezed,
    Object? dateEnd = freezed,
    Object? jobOrderStatus = null,
    Object? jobOrderStatusToString = null,
    Object? merchantID = null,
    Object? address = null,
    Object? numberOfPersonnel = null,
    Object? distanceFromOffice = null,
    Object? merchantServiceName = null,
    Object? merchantServicePhoto = null,
    Object? actualDateStart = freezed,
    Object? actualDateEnd = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? note = freezed,
    Object? downPayment = null,
    Object? totalAmount = null,
    Object? paymentType = null,
    Object? viewDate = freezed,
    Object? cancelledBy = freezed,
    Object? createdDate = null,
    Object? paymentStatus = freezed,
    Object? paymentMethodUsed = freezed,
  }) {
    return _then(_value.copyWith(
      jobOrderID: null == jobOrderID
          ? _value.jobOrderID
          : jobOrderID // ignore: cast_nullable_to_non_nullable
              as String,
      jobOrderNumber: null == jobOrderNumber
          ? _value.jobOrderNumber
          : jobOrderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      merchantName: null == merchantName
          ? _value.merchantName
          : merchantName // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleDate: null == scheduleDate
          ? _value.scheduleDate
          : scheduleDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dateStart: freezed == dateStart
          ? _value.dateStart
          : dateStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateEnd: freezed == dateEnd
          ? _value.dateEnd
          : dateEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      jobOrderStatus: null == jobOrderStatus
          ? _value.jobOrderStatus
          : jobOrderStatus // ignore: cast_nullable_to_non_nullable
              as JobOrderStatus,
      jobOrderStatusToString: null == jobOrderStatusToString
          ? _value.jobOrderStatusToString
          : jobOrderStatusToString // ignore: cast_nullable_to_non_nullable
              as String,
      merchantID: null == merchantID
          ? _value.merchantID
          : merchantID // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      numberOfPersonnel: null == numberOfPersonnel
          ? _value.numberOfPersonnel
          : numberOfPersonnel // ignore: cast_nullable_to_non_nullable
              as int,
      distanceFromOffice: null == distanceFromOffice
          ? _value.distanceFromOffice
          : distanceFromOffice // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceName: null == merchantServiceName
          ? _value.merchantServiceName
          : merchantServiceName // ignore: cast_nullable_to_non_nullable
              as String,
      merchantServicePhoto: null == merchantServicePhoto
          ? _value.merchantServicePhoto
          : merchantServicePhoto // ignore: cast_nullable_to_non_nullable
              as String,
      actualDateStart: freezed == actualDateStart
          ? _value.actualDateStart
          : actualDateStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualDateEnd: freezed == actualDateEnd
          ? _value.actualDateEnd
          : actualDateEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      downPayment: null == downPayment
          ? _value.downPayment
          : downPayment // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      paymentType: null == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int,
      viewDate: freezed == viewDate
          ? _value.viewDate
          : viewDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledBy: freezed == cancelledBy
          ? _value.cancelledBy
          : cancelledBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      paymentStatus: freezed == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentMethodUsed: freezed == paymentMethodUsed
          ? _value.paymentMethodUsed
          : paymentMethodUsed // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JobOrderImplCopyWith<$Res>
    implements $JobOrderCopyWith<$Res> {
  factory _$$JobOrderImplCopyWith(
          _$JobOrderImpl value, $Res Function(_$JobOrderImpl) then) =
      __$$JobOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String jobOrderID,
      String jobOrderNumber,
      String merchantName,
      DateTime scheduleDate,
      DateTime? dateStart,
      DateTime? dateEnd,
      @JsonKey(fromJson: intToJobStatus) JobOrderStatus jobOrderStatus,
      String jobOrderStatusToString,
      String merchantID,
      String address,
      int numberOfPersonnel,
      int distanceFromOffice,
      String merchantServiceName,
      String merchantServicePhoto,
      DateTime? actualDateStart,
      DateTime? actualDateEnd,
      double latitude,
      double longitude,
      String? note,
      double downPayment,
      double totalAmount,
      int paymentType,
      DateTime? viewDate,
      String? cancelledBy,
      DateTime createdDate,
      String? paymentStatus,
      String? paymentMethodUsed});
}

/// @nodoc
class __$$JobOrderImplCopyWithImpl<$Res>
    extends _$JobOrderCopyWithImpl<$Res, _$JobOrderImpl>
    implements _$$JobOrderImplCopyWith<$Res> {
  __$$JobOrderImplCopyWithImpl(
      _$JobOrderImpl _value, $Res Function(_$JobOrderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobOrderID = null,
    Object? jobOrderNumber = null,
    Object? merchantName = null,
    Object? scheduleDate = null,
    Object? dateStart = freezed,
    Object? dateEnd = freezed,
    Object? jobOrderStatus = null,
    Object? jobOrderStatusToString = null,
    Object? merchantID = null,
    Object? address = null,
    Object? numberOfPersonnel = null,
    Object? distanceFromOffice = null,
    Object? merchantServiceName = null,
    Object? merchantServicePhoto = null,
    Object? actualDateStart = freezed,
    Object? actualDateEnd = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? note = freezed,
    Object? downPayment = null,
    Object? totalAmount = null,
    Object? paymentType = null,
    Object? viewDate = freezed,
    Object? cancelledBy = freezed,
    Object? createdDate = null,
    Object? paymentStatus = freezed,
    Object? paymentMethodUsed = freezed,
  }) {
    return _then(_$JobOrderImpl(
      jobOrderID: null == jobOrderID
          ? _value.jobOrderID
          : jobOrderID // ignore: cast_nullable_to_non_nullable
              as String,
      jobOrderNumber: null == jobOrderNumber
          ? _value.jobOrderNumber
          : jobOrderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      merchantName: null == merchantName
          ? _value.merchantName
          : merchantName // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleDate: null == scheduleDate
          ? _value.scheduleDate
          : scheduleDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dateStart: freezed == dateStart
          ? _value.dateStart
          : dateStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateEnd: freezed == dateEnd
          ? _value.dateEnd
          : dateEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      jobOrderStatus: null == jobOrderStatus
          ? _value.jobOrderStatus
          : jobOrderStatus // ignore: cast_nullable_to_non_nullable
              as JobOrderStatus,
      jobOrderStatusToString: null == jobOrderStatusToString
          ? _value.jobOrderStatusToString
          : jobOrderStatusToString // ignore: cast_nullable_to_non_nullable
              as String,
      merchantID: null == merchantID
          ? _value.merchantID
          : merchantID // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      numberOfPersonnel: null == numberOfPersonnel
          ? _value.numberOfPersonnel
          : numberOfPersonnel // ignore: cast_nullable_to_non_nullable
              as int,
      distanceFromOffice: null == distanceFromOffice
          ? _value.distanceFromOffice
          : distanceFromOffice // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceName: null == merchantServiceName
          ? _value.merchantServiceName
          : merchantServiceName // ignore: cast_nullable_to_non_nullable
              as String,
      merchantServicePhoto: null == merchantServicePhoto
          ? _value.merchantServicePhoto
          : merchantServicePhoto // ignore: cast_nullable_to_non_nullable
              as String,
      actualDateStart: freezed == actualDateStart
          ? _value.actualDateStart
          : actualDateStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualDateEnd: freezed == actualDateEnd
          ? _value.actualDateEnd
          : actualDateEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      downPayment: null == downPayment
          ? _value.downPayment
          : downPayment // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      paymentType: null == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int,
      viewDate: freezed == viewDate
          ? _value.viewDate
          : viewDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledBy: freezed == cancelledBy
          ? _value.cancelledBy
          : cancelledBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      paymentStatus: freezed == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentMethodUsed: freezed == paymentMethodUsed
          ? _value.paymentMethodUsed
          : paymentMethodUsed // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JobOrderImpl implements _JobOrder {
  const _$JobOrderImpl(
      {required this.jobOrderID,
      required this.jobOrderNumber,
      this.merchantName = "Unknown merchant",
      required this.scheduleDate,
      this.dateStart,
      this.dateEnd,
      @JsonKey(fromJson: intToJobStatus)
      this.jobOrderStatus = JobOrderStatus.none,
      required this.jobOrderStatusToString,
      this.merchantID = "null",
      required this.address,
      required this.numberOfPersonnel,
      required this.distanceFromOffice,
      required this.merchantServiceName,
      this.merchantServicePhoto = '',
      this.actualDateStart,
      this.actualDateEnd,
      required this.latitude,
      required this.longitude,
      this.note,
      required this.downPayment,
      required this.totalAmount,
      required this.paymentType,
      this.viewDate,
      this.cancelledBy,
      required this.createdDate,
      this.paymentStatus,
      this.paymentMethodUsed});

  factory _$JobOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobOrderImplFromJson(json);

  @override
  final String jobOrderID;
  @override
  final String jobOrderNumber;
  @override
  @JsonKey()
  final String merchantName;
  @override
  final DateTime scheduleDate;
  @override
  final DateTime? dateStart;
  @override
  final DateTime? dateEnd;
  @override
  @JsonKey(fromJson: intToJobStatus)
  final JobOrderStatus jobOrderStatus;
  @override
  final String jobOrderStatusToString;
  @override
  @JsonKey()
  final String merchantID;
  @override
  final String address;
  @override
  final int numberOfPersonnel;
  @override
  final int distanceFromOffice;
  @override
  final String merchantServiceName;
  @override
  @JsonKey()
  final String merchantServicePhoto;
  @override
  final DateTime? actualDateStart;
  @override
  final DateTime? actualDateEnd;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String? note;
  @override
  final double downPayment;
  @override
  final double totalAmount;
  @override
  final int paymentType;
  @override
  final DateTime? viewDate;
  @override
  final String? cancelledBy;
  @override
  final DateTime createdDate;
  @override
  final String? paymentStatus;
  @override
  final String? paymentMethodUsed;

  @override
  String toString() {
    return 'JobOrder(jobOrderID: $jobOrderID, jobOrderNumber: $jobOrderNumber, merchantName: $merchantName, scheduleDate: $scheduleDate, dateStart: $dateStart, dateEnd: $dateEnd, jobOrderStatus: $jobOrderStatus, jobOrderStatusToString: $jobOrderStatusToString, merchantID: $merchantID, address: $address, numberOfPersonnel: $numberOfPersonnel, distanceFromOffice: $distanceFromOffice, merchantServiceName: $merchantServiceName, merchantServicePhoto: $merchantServicePhoto, actualDateStart: $actualDateStart, actualDateEnd: $actualDateEnd, latitude: $latitude, longitude: $longitude, note: $note, downPayment: $downPayment, totalAmount: $totalAmount, paymentType: $paymentType, viewDate: $viewDate, cancelledBy: $cancelledBy, createdDate: $createdDate, paymentStatus: $paymentStatus, paymentMethodUsed: $paymentMethodUsed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobOrderImpl &&
            (identical(other.jobOrderID, jobOrderID) ||
                other.jobOrderID == jobOrderID) &&
            (identical(other.jobOrderNumber, jobOrderNumber) ||
                other.jobOrderNumber == jobOrderNumber) &&
            (identical(other.merchantName, merchantName) ||
                other.merchantName == merchantName) &&
            (identical(other.scheduleDate, scheduleDate) ||
                other.scheduleDate == scheduleDate) &&
            (identical(other.dateStart, dateStart) ||
                other.dateStart == dateStart) &&
            (identical(other.dateEnd, dateEnd) || other.dateEnd == dateEnd) &&
            (identical(other.jobOrderStatus, jobOrderStatus) ||
                other.jobOrderStatus == jobOrderStatus) &&
            (identical(other.jobOrderStatusToString, jobOrderStatusToString) ||
                other.jobOrderStatusToString == jobOrderStatusToString) &&
            (identical(other.merchantID, merchantID) ||
                other.merchantID == merchantID) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.numberOfPersonnel, numberOfPersonnel) ||
                other.numberOfPersonnel == numberOfPersonnel) &&
            (identical(other.distanceFromOffice, distanceFromOffice) ||
                other.distanceFromOffice == distanceFromOffice) &&
            (identical(other.merchantServiceName, merchantServiceName) ||
                other.merchantServiceName == merchantServiceName) &&
            (identical(other.merchantServicePhoto, merchantServicePhoto) ||
                other.merchantServicePhoto == merchantServicePhoto) &&
            (identical(other.actualDateStart, actualDateStart) ||
                other.actualDateStart == actualDateStart) &&
            (identical(other.actualDateEnd, actualDateEnd) ||
                other.actualDateEnd == actualDateEnd) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.downPayment, downPayment) ||
                other.downPayment == downPayment) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.paymentType, paymentType) ||
                other.paymentType == paymentType) &&
            (identical(other.viewDate, viewDate) ||
                other.viewDate == viewDate) &&
            (identical(other.cancelledBy, cancelledBy) ||
                other.cancelledBy == cancelledBy) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.paymentMethodUsed, paymentMethodUsed) ||
                other.paymentMethodUsed == paymentMethodUsed));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        jobOrderID,
        jobOrderNumber,
        merchantName,
        scheduleDate,
        dateStart,
        dateEnd,
        jobOrderStatus,
        jobOrderStatusToString,
        merchantID,
        address,
        numberOfPersonnel,
        distanceFromOffice,
        merchantServiceName,
        merchantServicePhoto,
        actualDateStart,
        actualDateEnd,
        latitude,
        longitude,
        note,
        downPayment,
        totalAmount,
        paymentType,
        viewDate,
        cancelledBy,
        createdDate,
        paymentStatus,
        paymentMethodUsed
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JobOrderImplCopyWith<_$JobOrderImpl> get copyWith =>
      __$$JobOrderImplCopyWithImpl<_$JobOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobOrderImplToJson(
      this,
    );
  }
}

abstract class _JobOrder implements JobOrder {
  const factory _JobOrder(
      {required final String jobOrderID,
      required final String jobOrderNumber,
      final String merchantName,
      required final DateTime scheduleDate,
      final DateTime? dateStart,
      final DateTime? dateEnd,
      @JsonKey(fromJson: intToJobStatus) final JobOrderStatus jobOrderStatus,
      required final String jobOrderStatusToString,
      final String merchantID,
      required final String address,
      required final int numberOfPersonnel,
      required final int distanceFromOffice,
      required final String merchantServiceName,
      final String merchantServicePhoto,
      final DateTime? actualDateStart,
      final DateTime? actualDateEnd,
      required final double latitude,
      required final double longitude,
      final String? note,
      required final double downPayment,
      required final double totalAmount,
      required final int paymentType,
      final DateTime? viewDate,
      final String? cancelledBy,
      required final DateTime createdDate,
      final String? paymentStatus,
      final String? paymentMethodUsed}) = _$JobOrderImpl;

  factory _JobOrder.fromJson(Map<String, dynamic> json) =
      _$JobOrderImpl.fromJson;

  @override
  String get jobOrderID;
  @override
  String get jobOrderNumber;
  @override
  String get merchantName;
  @override
  DateTime get scheduleDate;
  @override
  DateTime? get dateStart;
  @override
  DateTime? get dateEnd;
  @override
  @JsonKey(fromJson: intToJobStatus)
  JobOrderStatus get jobOrderStatus;
  @override
  String get jobOrderStatusToString;
  @override
  String get merchantID;
  @override
  String get address;
  @override
  int get numberOfPersonnel;
  @override
  int get distanceFromOffice;
  @override
  String get merchantServiceName;
  @override
  String get merchantServicePhoto;
  @override
  DateTime? get actualDateStart;
  @override
  DateTime? get actualDateEnd;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String? get note;
  @override
  double get downPayment;
  @override
  double get totalAmount;
  @override
  int get paymentType;
  @override
  DateTime? get viewDate;
  @override
  String? get cancelledBy;
  @override
  DateTime get createdDate;
  @override
  String? get paymentStatus;
  @override
  String? get paymentMethodUsed;
  @override
  @JsonKey(ignore: true)
  _$$JobOrderImplCopyWith<_$JobOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
