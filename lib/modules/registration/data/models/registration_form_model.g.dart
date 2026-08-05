// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_form_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegistrationFormModelAdapter extends TypeAdapter<RegistrationFormModel> {
  @override
  final int typeId = 0;

  @override
  RegistrationFormModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegistrationFormModel(
      ownerName: fields[1] as String?,
      ownerEmail: fields[2] as String?,
      ownerPhoneNo: fields[3] as String?,
      nameOfBusiness: fields[6] as String?,
      typeOfBusiness: fields[7] as String?,
      businessPhone: fields[8] as String?,
      businessLocationCoordinates: fields[9] as LocationCoordinatesModel?,
      province: fields[41] as String?,
      country: fields[42] as String?,
      postalCode: fields[43] as String?,
      city: fields[10] as String?,
      barangay: fields[11] as String?,
      streetAddress: fields[12] as String?,
      listTittle: fields[13] as String?,
      banner: fields[14] as String?,
      certificateOfRegistration: fields[15] as String?,
      certificateOfRegistrationFile: fields[16] as XFileMod?,
      businessPermit: fields[17] as String?,
      businessPermitFile: fields[18] as XFileMod?,
      bir2303: fields[19] as String?,
      bir2303File: fields[20] as XFileMod?,
      bank: fields[21] as String?,
      bankAccountHolder: fields[22] as String?,
      bankAccountNumber: fields[23] as String?,
      bankCertificate: fields[24] as XFileMod?,
      bankCertificateFile: fields[25] as XFileMod?,
      bankAccountHolderIdType: fields[26] as String?,
      bankAccountHolderIdNumber: fields[27] as String?,
      bankAccountHolderIdFront: fields[28] as String?,
      bankAccountHolderIdFrontFile: fields[29] as XFileMod?,
      bankAccountHolderIdBack: fields[30] as String?,
      bankAccountHolderIdBackFile: fields[31] as XFileMod?,
      authorizedPersonelName: fields[32] as String?,
      authorizedPersonelIdType: fields[33] as String?,
      authorizedPersonelIdNumer: fields[34] as String?,
      authorizedPersonelIdFront: fields[35] as String?,
      authorizedPersonelIdFrontFile: fields[36] as XFileMod?,
      authorizedPersonelIdBack: fields[37] as String?,
      authorizedPersonelIdBackFile: fields[38] as XFileMod?,
      listPicture: fields[39] as XFileMod?,
      bannerPicture: fields[40] as XFileMod?,
    );
  }

  @override
  void write(BinaryWriter writer, RegistrationFormModel obj) {
    writer
      ..writeByte(41)
      ..writeByte(1)
      ..write(obj.ownerName)
      ..writeByte(2)
      ..write(obj.ownerEmail)
      ..writeByte(3)
      ..write(obj.ownerPhoneNo)
      ..writeByte(6)
      ..write(obj.nameOfBusiness)
      ..writeByte(7)
      ..write(obj.typeOfBusiness)
      ..writeByte(8)
      ..write(obj.businessPhone)
      ..writeByte(9)
      ..write(obj.businessLocationCoordinates)
      ..writeByte(41)
      ..write(obj.province)
      ..writeByte(42)
      ..write(obj.country)
      ..writeByte(43)
      ..write(obj.postalCode)
      ..writeByte(10)
      ..write(obj.city)
      ..writeByte(11)
      ..write(obj.barangay)
      ..writeByte(12)
      ..write(obj.streetAddress)
      ..writeByte(13)
      ..write(obj.listTittle)
      ..writeByte(14)
      ..write(obj.banner)
      ..writeByte(15)
      ..write(obj.certificateOfRegistration)
      ..writeByte(16)
      ..write(obj.certificateOfRegistrationFile)
      ..writeByte(17)
      ..write(obj.businessPermit)
      ..writeByte(18)
      ..write(obj.businessPermitFile)
      ..writeByte(19)
      ..write(obj.bir2303)
      ..writeByte(20)
      ..write(obj.bir2303File)
      ..writeByte(21)
      ..write(obj.bank)
      ..writeByte(22)
      ..write(obj.bankAccountHolder)
      ..writeByte(23)
      ..write(obj.bankAccountNumber)
      ..writeByte(24)
      ..write(obj.bankCertificate)
      ..writeByte(25)
      ..write(obj.bankCertificateFile)
      ..writeByte(26)
      ..write(obj.bankAccountHolderIdType)
      ..writeByte(27)
      ..write(obj.bankAccountHolderIdNumber)
      ..writeByte(28)
      ..write(obj.bankAccountHolderIdFront)
      ..writeByte(29)
      ..write(obj.bankAccountHolderIdFrontFile)
      ..writeByte(30)
      ..write(obj.bankAccountHolderIdBack)
      ..writeByte(31)
      ..write(obj.bankAccountHolderIdBackFile)
      ..writeByte(32)
      ..write(obj.authorizedPersonelName)
      ..writeByte(33)
      ..write(obj.authorizedPersonelIdType)
      ..writeByte(34)
      ..write(obj.authorizedPersonelIdNumer)
      ..writeByte(35)
      ..write(obj.authorizedPersonelIdFront)
      ..writeByte(36)
      ..write(obj.authorizedPersonelIdFrontFile)
      ..writeByte(37)
      ..write(obj.authorizedPersonelIdBack)
      ..writeByte(38)
      ..write(obj.authorizedPersonelIdBackFile)
      ..writeByte(39)
      ..write(obj.listPicture)
      ..writeByte(40)
      ..write(obj.bannerPicture);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistrationFormModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegistrationFormModelImpl _$$RegistrationFormModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RegistrationFormModelImpl(
      ownerName: json['ownerName'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      ownerPhoneNo: json['ownerPhoneNo'] as String?,
      nameOfBusiness: json['nameOfBusiness'] as String?,
      typeOfBusiness: json['typeOfBusiness'] as String?,
      businessPhone: json['businessPhone'] as String?,
      businessLocationCoordinates: json['businessLocationCoordinates'] == null
          ? null
          : LocationCoordinatesModel.fromJson(
              json['businessLocationCoordinates'] as Map<String, dynamic>),
      province: json['province'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      city: json['city'] as String?,
      barangay: json['barangay'] as String?,
      streetAddress: json['streetAddress'] as String?,
      listTittle: json['listTittle'] as String?,
      banner: json['banner'] as String?,
      certificateOfRegistration: json['certificateOfRegistration'] as String?,
      businessPermit: json['businessPermit'] as String?,
      bir2303: json['bir2303'] as String?,
      bank: json['bank'] as String?,
      bankAccountHolder: json['bankAccountHolder'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankAccountHolderIdType: json['bankAccountHolderIdType'] as String?,
      bankAccountHolderIdNumber: json['bankAccountHolderIdNumber'] as String?,
      bankAccountHolderIdFront: json['bankAccountHolderIdFront'] as String?,
      bankAccountHolderIdBack: json['bankAccountHolderIdBack'] as String?,
      authorizedPersonelName: json['authorizedPersonelName'] as String?,
      authorizedPersonelIdType: json['authorizedPersonelIdType'] as String?,
      authorizedPersonelIdNumer: json['authorizedPersonelIdNumer'] as String?,
      authorizedPersonelIdFront: json['authorizedPersonelIdFront'] as String?,
      authorizedPersonelIdBack: json['authorizedPersonelIdBack'] as String?,
    );

Map<String, dynamic> _$$RegistrationFormModelImplToJson(
        _$RegistrationFormModelImpl instance) =>
    <String, dynamic>{
      'ownerName': instance.ownerName,
      'ownerEmail': instance.ownerEmail,
      'ownerPhoneNo': instance.ownerPhoneNo,
      'nameOfBusiness': instance.nameOfBusiness,
      'typeOfBusiness': instance.typeOfBusiness,
      'businessPhone': instance.businessPhone,
      'businessLocationCoordinates': instance.businessLocationCoordinates,
      'province': instance.province,
      'country': instance.country,
      'postalCode': instance.postalCode,
      'city': instance.city,
      'barangay': instance.barangay,
      'streetAddress': instance.streetAddress,
      'listTittle': instance.listTittle,
      'banner': instance.banner,
      'certificateOfRegistration': instance.certificateOfRegistration,
      'businessPermit': instance.businessPermit,
      'bir2303': instance.bir2303,
      'bank': instance.bank,
      'bankAccountHolder': instance.bankAccountHolder,
      'bankAccountNumber': instance.bankAccountNumber,
      'bankAccountHolderIdType': instance.bankAccountHolderIdType,
      'bankAccountHolderIdNumber': instance.bankAccountHolderIdNumber,
      'bankAccountHolderIdFront': instance.bankAccountHolderIdFront,
      'bankAccountHolderIdBack': instance.bankAccountHolderIdBack,
      'authorizedPersonelName': instance.authorizedPersonelName,
      'authorizedPersonelIdType': instance.authorizedPersonelIdType,
      'authorizedPersonelIdNumer': instance.authorizedPersonelIdNumer,
      'authorizedPersonelIdFront': instance.authorizedPersonelIdFront,
      'authorizedPersonelIdBack': instance.authorizedPersonelIdBack,
    };
