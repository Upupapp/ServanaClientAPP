import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_service_result.freezed.dart';
part 'search_service_result.g.dart';

@freezed
class SearchServiceResult with _$SearchServiceResult {
  const factory SearchServiceResult({
    required String merchantID,
    required String merchantName,
    required int merchantStatus,
    required String merchantStatusToString,
    required String city,
    required String barangay,
    required double longitude,
    required double latitude,
    required int rating,
    required String listImage,
    required int merchantServiceID,
    required String merchantServiceName,
    required double amount,
    required String merchantServicePictureURL,
    required List<int> discounts,
  }) = _SearchServiceResult;

  factory SearchServiceResult.fromJson(Map<String, dynamic> json) =>
      _$SearchServiceResultFromJson(json);
}
