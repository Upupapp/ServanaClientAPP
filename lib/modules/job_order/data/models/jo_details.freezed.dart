// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jo_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JobOrderDetails _$JobOrderDetailsFromJson(Map<String, dynamic> json) {
  return _JobOrderDetails.fromJson(json);
}

/// @nodoc
mixin _$JobOrderDetails {
  String get jobOrderID => throw _privateConstructorUsedError;
  String get customerID => throw _privateConstructorUsedError;
  String get merchantID => throw _privateConstructorUsedError;
  String? get voucherCode => throw _privateConstructorUsedError;
  String get jobOrderNumber => throw _privateConstructorUsedError;
  @JsonKey(fromJson: intToJobStatus)
  JobOrderStatus get jobOrderStatus => throw _privateConstructorUsedError;
  DateTime get scheduleDate => throw _privateConstructorUsedError;
  DateTime? get dateStart => throw _privateConstructorUsedError;
  DateTime? get dateEnd => throw _privateConstructorUsedError;
  DateTime? get actualDateStart => throw _privateConstructorUsedError;
  DateTime? get actualDateEnd => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get note => throw _privateConstructorUsedError;
  double get distanceFromOffice => throw _privateConstructorUsedError;
  int get numberOfPersonnel => throw _privateConstructorUsedError;
  double? get totalItemAmount => throw _privateConstructorUsedError;
  double? get totalItemDiscount => throw _privateConstructorUsedError;
  double? get subDiscountAmount => throw _privateConstructorUsedError;
  double? get subDiscountPercent => throw _privateConstructorUsedError;
  double? get downPayment => throw _privateConstructorUsedError;
  double get transportationFee => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  DateTime? get viewDate => throw _privateConstructorUsedError;
  String? get cancelledBy => throw _privateConstructorUsedError;
  double get earnedCredit => throw _privateConstructorUsedError;
  int get paymentType => throw _privateConstructorUsedError;
  DateTime get createdDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $JobOrderDetailsCopyWith<JobOrderDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobOrderDetailsCopyWith<$Res> {
  factory $JobOrderDetailsCopyWith(
          JobOrderDetails value, $Res Function(JobOrderDetails) then) =
      _$JobOrderDetailsCopyWithImpl<$Res, JobOrderDetails>;
  @useResult
  $Res call(
      {String jobOrderID,
      String customerID,
      String merchantID,
      String? voucherCode,
      String jobOrderNumber,
      @JsonKey(fromJson: intToJobStatus) JobOrderStatus jobOrderStatus,
      DateTime scheduleDate,
      DateTime? dateStart,
      DateTime? dateEnd,
      DateTime? actualDateStart,
      DateTime? actualDateEnd,
      String address,
      double latitude,
      double longitude,
      String note,
      double distanceFromOffice,
      int numberOfPersonnel,
      double? totalItemAmount,
      double? totalItemDiscount,
      double? subDiscountAmount,
      double? subDiscountPercent,
      double? downPayment,
      double transportationFee,
      double totalAmount,
      DateTime? viewDate,
      String? cancelledBy,
      double earnedCredit,
      int paymentType,
      DateTime createdDate});
}

/// @nodoc
class _$JobOrderDetailsCopyWithImpl<$Res, $Val extends JobOrderDetails>
    implements $JobOrderDetailsCopyWith<$Res> {
  _$JobOrderDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobOrderID = null,
    Object? customerID = null,
    Object? merchantID = null,
    Object? voucherCode = freezed,
    Object? jobOrderNumber = null,
    Object? jobOrderStatus = null,
    Object? scheduleDate = null,
    Object? dateStart = freezed,
    Object? dateEnd = freezed,
    Object? actualDateStart = freezed,
    Object? actualDateEnd = freezed,
    Object? address = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? note = null,
    Object? distanceFromOffice = null,
    Object? numberOfPersonnel = null,
    Object? totalItemAmount = freezed,
    Object? totalItemDiscount = freezed,
    Object? subDiscountAmount = freezed,
    Object? subDiscountPercent = freezed,
    Object? downPayment = freezed,
    Object? transportationFee = null,
    Object? totalAmount = null,
    Object? viewDate = freezed,
    Object? cancelledBy = freezed,
    Object? earnedCredit = null,
    Object? paymentType = null,
    Object? createdDate = null,
  }) {
    return _then(_value.copyWith(
      jobOrderID: null == jobOrderID
          ? _value.jobOrderID
          : jobOrderID // ignore: cast_nullable_to_non_nullable
              as String,
      customerID: null == customerID
          ? _value.customerID
          : customerID // ignore: cast_nullable_to_non_nullable
              as String,
      merchantID: null == merchantID
          ? _value.merchantID
          : merchantID // ignore: cast_nullable_to_non_nullable
              as String,
      voucherCode: freezed == voucherCode
          ? _value.voucherCode
          : voucherCode // ignore: cast_nullable_to_non_nullable
              as String?,
      jobOrderNumber: null == jobOrderNumber
          ? _value.jobOrderNumber
          : jobOrderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      jobOrderStatus: null == jobOrderStatus
          ? _value.jobOrderStatus
          : jobOrderStatus // ignore: cast_nullable_to_non_nullable
              as JobOrderStatus,
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
      actualDateStart: freezed == actualDateStart
          ? _value.actualDateStart
          : actualDateStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualDateEnd: freezed == actualDateEnd
          ? _value.actualDateEnd
          : actualDateEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      distanceFromOffice: null == distanceFromOffice
          ? _value.distanceFromOffice
          : distanceFromOffice // ignore: cast_nullable_to_non_nullable
              as double,
      numberOfPersonnel: null == numberOfPersonnel
          ? _value.numberOfPersonnel
          : numberOfPersonnel // ignore: cast_nullable_to_non_nullable
              as int,
      totalItemAmount: freezed == totalItemAmount
          ? _value.totalItemAmount
          : totalItemAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      totalItemDiscount: freezed == totalItemDiscount
          ? _value.totalItemDiscount
          : totalItemDiscount // ignore: cast_nullable_to_non_nullable
              as double?,
      subDiscountAmount: freezed == subDiscountAmount
          ? _value.subDiscountAmount
          : subDiscountAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      subDiscountPercent: freezed == subDiscountPercent
          ? _value.subDiscountPercent
          : subDiscountPercent // ignore: cast_nullable_to_non_nullable
              as double?,
      downPayment: freezed == downPayment
          ? _value.downPayment
          : downPayment // ignore: cast_nullable_to_non_nullable
              as double?,
      transportationFee: null == transportationFee
          ? _value.transportationFee
          : transportationFee // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      viewDate: freezed == viewDate
          ? _value.viewDate
          : viewDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledBy: freezed == cancelledBy
          ? _value.cancelledBy
          : cancelledBy // ignore: cast_nullable_to_non_nullable
              as String?,
      earnedCredit: null == earnedCredit
          ? _value.earnedCredit
          : earnedCredit // ignore: cast_nullable_to_non_nullable
              as double,
      paymentType: null == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JobOrderDetailsImplCopyWith<$Res>
    implements $JobOrderDetailsCopyWith<$Res> {
  factory _$$JobOrderDetailsImplCopyWith(_$JobOrderDetailsImpl value,
          $Res Function(_$JobOrderDetailsImpl) then) =
      __$$JobOrderDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String jobOrderID,
      String customerID,
      String merchantID,
      String? voucherCode,
      String jobOrderNumber,
      @JsonKey(fromJson: intToJobStatus) JobOrderStatus jobOrderStatus,
      DateTime scheduleDate,
      DateTime? dateStart,
      DateTime? dateEnd,
      DateTime? actualDateStart,
      DateTime? actualDateEnd,
      String address,
      double latitude,
      double longitude,
      String note,
      double distanceFromOffice,
      int numberOfPersonnel,
      double? totalItemAmount,
      double? totalItemDiscount,
      double? subDiscountAmount,
      double? subDiscountPercent,
      double? downPayment,
      double transportationFee,
      double totalAmount,
      DateTime? viewDate,
      String? cancelledBy,
      double earnedCredit,
      int paymentType,
      DateTime createdDate});
}

/// @nodoc
class __$$JobOrderDetailsImplCopyWithImpl<$Res>
    extends _$JobOrderDetailsCopyWithImpl<$Res, _$JobOrderDetailsImpl>
    implements _$$JobOrderDetailsImplCopyWith<$Res> {
  __$$JobOrderDetailsImplCopyWithImpl(
      _$JobOrderDetailsImpl _value, $Res Function(_$JobOrderDetailsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobOrderID = null,
    Object? customerID = null,
    Object? merchantID = null,
    Object? voucherCode = freezed,
    Object? jobOrderNumber = null,
    Object? jobOrderStatus = null,
    Object? scheduleDate = null,
    Object? dateStart = freezed,
    Object? dateEnd = freezed,
    Object? actualDateStart = freezed,
    Object? actualDateEnd = freezed,
    Object? address = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? note = null,
    Object? distanceFromOffice = null,
    Object? numberOfPersonnel = null,
    Object? totalItemAmount = freezed,
    Object? totalItemDiscount = freezed,
    Object? subDiscountAmount = freezed,
    Object? subDiscountPercent = freezed,
    Object? downPayment = freezed,
    Object? transportationFee = null,
    Object? totalAmount = null,
    Object? viewDate = freezed,
    Object? cancelledBy = freezed,
    Object? earnedCredit = null,
    Object? paymentType = null,
    Object? createdDate = null,
  }) {
    return _then(_$JobOrderDetailsImpl(
      jobOrderID: null == jobOrderID
          ? _value.jobOrderID
          : jobOrderID // ignore: cast_nullable_to_non_nullable
              as String,
      customerID: null == customerID
          ? _value.customerID
          : customerID // ignore: cast_nullable_to_non_nullable
              as String,
      merchantID: null == merchantID
          ? _value.merchantID
          : merchantID // ignore: cast_nullable_to_non_nullable
              as String,
      voucherCode: freezed == voucherCode
          ? _value.voucherCode
          : voucherCode // ignore: cast_nullable_to_non_nullable
              as String?,
      jobOrderNumber: null == jobOrderNumber
          ? _value.jobOrderNumber
          : jobOrderNumber // ignore: cast_nullable_to_non_nullable
              as String,
      jobOrderStatus: null == jobOrderStatus
          ? _value.jobOrderStatus
          : jobOrderStatus // ignore: cast_nullable_to_non_nullable
              as JobOrderStatus,
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
      actualDateStart: freezed == actualDateStart
          ? _value.actualDateStart
          : actualDateStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualDateEnd: freezed == actualDateEnd
          ? _value.actualDateEnd
          : actualDateEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      distanceFromOffice: null == distanceFromOffice
          ? _value.distanceFromOffice
          : distanceFromOffice // ignore: cast_nullable_to_non_nullable
              as double,
      numberOfPersonnel: null == numberOfPersonnel
          ? _value.numberOfPersonnel
          : numberOfPersonnel // ignore: cast_nullable_to_non_nullable
              as int,
      totalItemAmount: freezed == totalItemAmount
          ? _value.totalItemAmount
          : totalItemAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      totalItemDiscount: freezed == totalItemDiscount
          ? _value.totalItemDiscount
          : totalItemDiscount // ignore: cast_nullable_to_non_nullable
              as double?,
      subDiscountAmount: freezed == subDiscountAmount
          ? _value.subDiscountAmount
          : subDiscountAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      subDiscountPercent: freezed == subDiscountPercent
          ? _value.subDiscountPercent
          : subDiscountPercent // ignore: cast_nullable_to_non_nullable
              as double?,
      downPayment: freezed == downPayment
          ? _value.downPayment
          : downPayment // ignore: cast_nullable_to_non_nullable
              as double?,
      transportationFee: null == transportationFee
          ? _value.transportationFee
          : transportationFee // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      viewDate: freezed == viewDate
          ? _value.viewDate
          : viewDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledBy: freezed == cancelledBy
          ? _value.cancelledBy
          : cancelledBy // ignore: cast_nullable_to_non_nullable
              as String?,
      earnedCredit: null == earnedCredit
          ? _value.earnedCredit
          : earnedCredit // ignore: cast_nullable_to_non_nullable
              as double,
      paymentType: null == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JobOrderDetailsImpl implements _JobOrderDetails {
  const _$JobOrderDetailsImpl(
      {required this.jobOrderID,
      required this.customerID,
      required this.merchantID,
      this.voucherCode,
      required this.jobOrderNumber,
      @JsonKey(fromJson: intToJobStatus) required this.jobOrderStatus,
      required this.scheduleDate,
      required this.dateStart,
      required this.dateEnd,
      required this.actualDateStart,
      required this.actualDateEnd,
      required this.address,
      this.latitude = 0,
      this.longitude = 0,
      this.note = "",
      this.distanceFromOffice = 0,
      this.numberOfPersonnel = 0,
      this.totalItemAmount,
      this.totalItemDiscount,
      this.subDiscountAmount,
      this.subDiscountPercent,
      this.downPayment,
      this.transportationFee = 0,
      this.totalAmount = 0,
      this.viewDate,
      this.cancelledBy,
      this.earnedCredit = 0,
      this.paymentType = 0,
      required this.createdDate});

  factory _$JobOrderDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobOrderDetailsImplFromJson(json);

  @override
  final String jobOrderID;
  @override
  final String customerID;
  @override
  final String merchantID;
  @override
  final String? voucherCode;
  @override
  final String jobOrderNumber;
  @override
  @JsonKey(fromJson: intToJobStatus)
  final JobOrderStatus jobOrderStatus;
  @override
  final DateTime scheduleDate;
  @override
  final DateTime? dateStart;
  @override
  final DateTime? dateEnd;
  @override
  final DateTime? actualDateStart;
  @override
  final DateTime? actualDateEnd;
  @override
  final String address;
  @override
  @JsonKey()
  final double latitude;
  @override
  @JsonKey()
  final double longitude;
  @override
  @JsonKey()
  final String note;
  @override
  @JsonKey()
  final double distanceFromOffice;
  @override
  @JsonKey()
  final int numberOfPersonnel;
  @override
  final double? totalItemAmount;
  @override
  final double? totalItemDiscount;
  @override
  final double? subDiscountAmount;
  @override
  final double? subDiscountPercent;
  @override
  final double? downPayment;
  @override
  @JsonKey()
  final double transportationFee;
  @override
  @JsonKey()
  final double totalAmount;
  @override
  final DateTime? viewDate;
  @override
  final String? cancelledBy;
  @override
  @JsonKey()
  final double earnedCredit;
  @override
  @JsonKey()
  final int paymentType;
  @override
  final DateTime createdDate;

  @override
  String toString() {
    return 'JobOrderDetails(jobOrderID: $jobOrderID, customerID: $customerID, merchantID: $merchantID, voucherCode: $voucherCode, jobOrderNumber: $jobOrderNumber, jobOrderStatus: $jobOrderStatus, scheduleDate: $scheduleDate, dateStart: $dateStart, dateEnd: $dateEnd, actualDateStart: $actualDateStart, actualDateEnd: $actualDateEnd, address: $address, latitude: $latitude, longitude: $longitude, note: $note, distanceFromOffice: $distanceFromOffice, numberOfPersonnel: $numberOfPersonnel, totalItemAmount: $totalItemAmount, totalItemDiscount: $totalItemDiscount, subDiscountAmount: $subDiscountAmount, subDiscountPercent: $subDiscountPercent, downPayment: $downPayment, transportationFee: $transportationFee, totalAmount: $totalAmount, viewDate: $viewDate, cancelledBy: $cancelledBy, earnedCredit: $earnedCredit, paymentType: $paymentType, createdDate: $createdDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobOrderDetailsImpl &&
            (identical(other.jobOrderID, jobOrderID) ||
                other.jobOrderID == jobOrderID) &&
            (identical(other.customerID, customerID) ||
                other.customerID == customerID) &&
            (identical(other.merchantID, merchantID) ||
                other.merchantID == merchantID) &&
            (identical(other.voucherCode, voucherCode) ||
                other.voucherCode == voucherCode) &&
            (identical(other.jobOrderNumber, jobOrderNumber) ||
                other.jobOrderNumber == jobOrderNumber) &&
            (identical(other.jobOrderStatus, jobOrderStatus) ||
                other.jobOrderStatus == jobOrderStatus) &&
            (identical(other.scheduleDate, scheduleDate) ||
                other.scheduleDate == scheduleDate) &&
            (identical(other.dateStart, dateStart) ||
                other.dateStart == dateStart) &&
            (identical(other.dateEnd, dateEnd) || other.dateEnd == dateEnd) &&
            (identical(other.actualDateStart, actualDateStart) ||
                other.actualDateStart == actualDateStart) &&
            (identical(other.actualDateEnd, actualDateEnd) ||
                other.actualDateEnd == actualDateEnd) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.distanceFromOffice, distanceFromOffice) ||
                other.distanceFromOffice == distanceFromOffice) &&
            (identical(other.numberOfPersonnel, numberOfPersonnel) ||
                other.numberOfPersonnel == numberOfPersonnel) &&
            (identical(other.totalItemAmount, totalItemAmount) ||
                other.totalItemAmount == totalItemAmount) &&
            (identical(other.totalItemDiscount, totalItemDiscount) ||
                other.totalItemDiscount == totalItemDiscount) &&
            (identical(other.subDiscountAmount, subDiscountAmount) ||
                other.subDiscountAmount == subDiscountAmount) &&
            (identical(other.subDiscountPercent, subDiscountPercent) ||
                other.subDiscountPercent == subDiscountPercent) &&
            (identical(other.downPayment, downPayment) ||
                other.downPayment == downPayment) &&
            (identical(other.transportationFee, transportationFee) ||
                other.transportationFee == transportationFee) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.viewDate, viewDate) ||
                other.viewDate == viewDate) &&
            (identical(other.cancelledBy, cancelledBy) ||
                other.cancelledBy == cancelledBy) &&
            (identical(other.earnedCredit, earnedCredit) ||
                other.earnedCredit == earnedCredit) &&
            (identical(other.paymentType, paymentType) ||
                other.paymentType == paymentType) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        jobOrderID,
        customerID,
        merchantID,
        voucherCode,
        jobOrderNumber,
        jobOrderStatus,
        scheduleDate,
        dateStart,
        dateEnd,
        actualDateStart,
        actualDateEnd,
        address,
        latitude,
        longitude,
        note,
        distanceFromOffice,
        numberOfPersonnel,
        totalItemAmount,
        totalItemDiscount,
        subDiscountAmount,
        subDiscountPercent,
        downPayment,
        transportationFee,
        totalAmount,
        viewDate,
        cancelledBy,
        earnedCredit,
        paymentType,
        createdDate
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JobOrderDetailsImplCopyWith<_$JobOrderDetailsImpl> get copyWith =>
      __$$JobOrderDetailsImplCopyWithImpl<_$JobOrderDetailsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobOrderDetailsImplToJson(
      this,
    );
  }
}

abstract class _JobOrderDetails implements JobOrderDetails {
  const factory _JobOrderDetails(
      {required final String jobOrderID,
      required final String customerID,
      required final String merchantID,
      final String? voucherCode,
      required final String jobOrderNumber,
      @JsonKey(fromJson: intToJobStatus)
      required final JobOrderStatus jobOrderStatus,
      required final DateTime scheduleDate,
      required final DateTime? dateStart,
      required final DateTime? dateEnd,
      required final DateTime? actualDateStart,
      required final DateTime? actualDateEnd,
      required final String address,
      final double latitude,
      final double longitude,
      final String note,
      final double distanceFromOffice,
      final int numberOfPersonnel,
      final double? totalItemAmount,
      final double? totalItemDiscount,
      final double? subDiscountAmount,
      final double? subDiscountPercent,
      final double? downPayment,
      final double transportationFee,
      final double totalAmount,
      final DateTime? viewDate,
      final String? cancelledBy,
      final double earnedCredit,
      final int paymentType,
      required final DateTime createdDate}) = _$JobOrderDetailsImpl;

  factory _JobOrderDetails.fromJson(Map<String, dynamic> json) =
      _$JobOrderDetailsImpl.fromJson;

  @override
  String get jobOrderID;
  @override
  String get customerID;
  @override
  String get merchantID;
  @override
  String? get voucherCode;
  @override
  String get jobOrderNumber;
  @override
  @JsonKey(fromJson: intToJobStatus)
  JobOrderStatus get jobOrderStatus;
  @override
  DateTime get scheduleDate;
  @override
  DateTime? get dateStart;
  @override
  DateTime? get dateEnd;
  @override
  DateTime? get actualDateStart;
  @override
  DateTime? get actualDateEnd;
  @override
  String get address;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get note;
  @override
  double get distanceFromOffice;
  @override
  int get numberOfPersonnel;
  @override
  double? get totalItemAmount;
  @override
  double? get totalItemDiscount;
  @override
  double? get subDiscountAmount;
  @override
  double? get subDiscountPercent;
  @override
  double? get downPayment;
  @override
  double get transportationFee;
  @override
  double get totalAmount;
  @override
  DateTime? get viewDate;
  @override
  String? get cancelledBy;
  @override
  double get earnedCredit;
  @override
  int get paymentType;
  @override
  DateTime get createdDate;
  @override
  @JsonKey(ignore: true)
  _$$JobOrderDetailsImplCopyWith<_$JobOrderDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
