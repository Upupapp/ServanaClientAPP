/// Canonical customer profile — maps the GET /api/user/profile response.
/// Backend returns camelCase; all aliases resolved in [ProfileRepository].
class CustomerProfile {
  const CustomerProfile({
    required this.id,
    this.firstName,
    this.lastName,
    required this.email,
    this.isEmailVerified = false,
    this.phoneNumber,
    this.photoUrl,
    this.birthdate,
    this.gender,
    this.role = 3,
    this.createdDate,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String email;
  final bool isEmailVerified;
  final String? phoneNumber;
  final String? photoUrl;
  final String? birthdate;
  final String? gender;
  final int role;
  final DateTime? createdDate;

  String get displayName {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return email.isNotEmpty ? email.split('@').first : 'Customer';
  }

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return 'C';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  CustomerProfile copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoUrl,
    String? birthdate,
    String? gender,
    bool? isEmailVerified,
  }) {
    return CustomerProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      role: role,
      createdDate: createdDate,
    );
  }
}
