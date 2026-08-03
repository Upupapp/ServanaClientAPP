/// Completeness score derived from a [CustomerProfile] + address count.
/// Weights: name 20 pts, email verified 20 pts, phone 20 pts,
///          saved address 20 pts, photo 10 pts, birthdate 5 pts, gender 5 pts.
class AccountCompleteness {
  const AccountCompleteness({
    required this.hasName,
    required this.hasEmail,
    required this.isEmailVerified,
    required this.hasPhone,
    required this.hasSavedAddress,
    required this.hasPhoto,
    required this.hasBirthdate,
    required this.hasGender,
  });

  final bool hasName;
  final bool hasEmail;
  final bool isEmailVerified;
  final bool hasPhone;
  final bool hasSavedAddress;
  final bool hasPhoto;
  final bool hasBirthdate;
  final bool hasGender;

  int get score {
    var s = 0;
    if (hasName) s += 20;
    if (isEmailVerified) s += 20;
    if (hasPhone) s += 20;
    if (hasSavedAddress) s += 20;
    if (hasPhoto) s += 10;
    if (hasBirthdate) s += 5;
    if (hasGender) s += 5;
    return s;
  }

  /// Minimum required before a booking can be placed.
  bool get isBookingReady => hasName && hasPhone && hasSavedAddress;

  /// Human-readable label for the completion state.
  String get label {
    if (score >= 90) return 'Profile complete';
    if (score >= 60) return 'Almost there';
    if (score >= 30) return 'Getting started';
    return 'Set up your profile';
  }

  List<String> get pendingItems {
    final items = <String>[];
    if (!hasName) items.add('Add your name');
    if (!isEmailVerified) items.add('Verify your email');
    if (!hasPhone) items.add('Add a phone number');
    if (!hasSavedAddress) items.add('Add a saved address');
    if (!hasPhoto) items.add('Upload a profile photo');
    if (!hasBirthdate) items.add('Add your date of birth');
    if (!hasGender) items.add('Set your gender');
    return items;
  }
}
