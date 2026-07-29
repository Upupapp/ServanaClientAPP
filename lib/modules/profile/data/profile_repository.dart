import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/profile/domain/customer_profile.dart';

class ProfileRepository {
  ProfileRepository({required ServanaApiClient api}) : _api = api;

  final ServanaApiClient _api;

  /// Load the current authenticated user's full profile.
  /// Backend derives ownership from the JWT — no ID param needed.
  Future<CustomerProfile?> loadProfile() async {
    final res = await _api.loadProfile();
    final data = (res['data'] ?? res) as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return null;
    return _profileFromJson(data);
  }

  /// Update name, phone, birthdate, and/or gender in a single call.
  Future<void> updateProfile({
    String? fullname,
    String? mobileNumber,
    String? birthdate,
    String? gender,
  }) async {
    final payload = <String, dynamic>{};
    if (fullname != null && fullname.isNotEmpty) payload['fullname'] = fullname;
    if (mobileNumber != null) payload['mobileNumber'] = mobileNumber;
    if (birthdate != null) payload['birthdate'] = birthdate;
    if (gender != null) payload['gender'] = gender;
    if (payload.isEmpty) return;
    await _api.updateProfile(payload: payload);
  }

  /// Upload a profile photo via base64-encoded image data.
  /// Backend calls uploadInStorage() and stores the URL in user_profile.photo_url.
  Future<void> uploadPhoto(String base64Data) async {
    await _api.updateProfile(payload: {'photoFile': base64Data});
  }

  /// Remove the profile photo.
  Future<void> removePhoto() async {
    await _api.updateProfile(payload: {'photoUrl': ''});
  }

  /// Resend email verification OTP.
  Future<void> resendEmailVerification() async {
    await _api.resendEmailOtp();
  }

  /// Verify email with the OTP the user received.
  Future<void> verifyEmailOtp(String otp) async {
    await _api.verifyEmailOtp(otp: otp);
  }

  CustomerProfile _profileFromJson(Map<String, dynamic> data) {
    return CustomerProfile(
      id: _str(data, ['id', 'uid', 'customerID']) ?? '',
      firstName: _str(data, ['firstName', 'first_name']),
      lastName: _str(data, ['lastName', 'last_name']),
      email: _str(data, ['email', 'emailAddress', 'email_address']) ?? '',
      isEmailVerified:
          data['isEmailVerified'] == true ||
          data['is_email_verified'] == true,
      phoneNumber: _str(data, [
        'phoneNumber', 'phone_number', 'mobileNumber',
        'mobile_number', 'phone',
      ]),
      photoUrl: _str(data, ['photoUrl', 'photo_url']),
      birthdate: _str(data, ['birthdate', 'birth_date']),
      gender: _str(data, ['gender']),
      role: (data['role'] as num?)?.toInt() ?? 3,
      createdDate: _parseDate(data['createdDate'] ?? data['created_at']),
    );
  }

  String? _str(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return null;
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    try {
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }
}
