/// Who the caller is, as the server sees them.
///
/// ## Authentication is not profile completion
///
/// The Master Command for this tab asks for these to be separated, and they
/// were not. `CustomerProfile` currently answers both "is this person signed
/// in and verified" and "have they filled in their last name" — so a screen
/// that only needed the first had to load the second, and a profile refresh
/// became a way to discover you were signed out.
///
/// [Identity] is the authentication half only: who you are, which contact
/// channels you have proven, and nothing about how complete your customer
/// record is. `CustomerProfile` stays exactly as it is and remains the source
/// of truth for the profile half.
///
/// ## No client-supplied identifiers
///
/// Every field here is READ from a server response. Nothing in the app may
/// construct an [Identity] with an id of its choosing and have it believed:
/// the canonical source reads `GET /api/v1/me`, which derives the subject from
/// the bearer token, and the compatibility source reads the profile route the
/// same way. That is why there is no `Identity.forUid(...)` constructor and
/// why [uid] has no setter — authorization must never follow a value the
/// client picked.
library;

/// Whether a contact channel has been proven.
///
/// Three states, not a bool: "this account has no mobile number at all" and
/// "this account has an unverified mobile number" lead to different screens,
/// and collapsing them into `false` is how a customer gets asked to verify a
/// number they never gave.
enum ChannelVerification {
  /// The account does not have this channel.
  absent,

  /// Present and not yet proven.
  unverified,

  /// Proven.
  verified;

  bool get isVerified => this == ChannelVerification.verified;
  bool get needsVerification => this == ChannelVerification.unverified;
}

class Identity {
  const Identity({
    required this.uid,
    this.email,
    this.mobileNumber,
    this.displayName,
    this.emailVerification = ChannelVerification.absent,
    this.mobileVerification = ChannelVerification.absent,
  });

  /// The server's subject for this session. Never client-supplied.
  final String uid;

  final String? email;
  final String? mobileNumber;
  final String? displayName;

  final ChannelVerification emailVerification;
  final ChannelVerification mobileVerification;

  /// True when at least one contact channel is proven.
  ///
  /// The backend supports email, mobile or both, so "verified" cannot mean
  /// "email verified" — an account that proved a mobile number and never gave
  /// an email is fully verified and must not be sent to an email OTP screen.
  bool get hasVerifiedChannel =>
      emailVerification.isVerified || mobileVerification.isVerified;

  /// Channels that exist and still need proving.
  List<String> get pendingChannels => <String>[
        if (emailVerification.needsVerification) 'email',
        if (mobileVerification.needsVerification) 'mobile',
      ];

  /// Reads the canonical `GET /api/v1/me` payload.
  ///
  /// Also tolerates the legacy profile shape, because the compatibility source
  /// feeds the same constructor — the two differ in field names and not in
  /// meaning, and absorbing that here is what keeps one model above the
  /// boundary.
  factory Identity.fromJson(Map<String, dynamic> json) {
    String? str(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    final email = str(['email', 'emailAddress', 'email_address']);
    final mobile = str(
        ['mobileNumber', 'phoneNumber', 'mobile', 'phone', 'contactNumber']);

    return Identity(
      uid: str(['uid', 'id', 'customerID', 'customerId']) ?? '',
      email: email,
      mobileNumber: mobile,
      displayName: str(['displayName', 'fullname', 'fullName', 'name']),
      emailVerification: _channel(
        present: email != null,
        verified:
            _bool(json, ['emailVerified', 'email_verified', 'isEmailVerified']),
      ),
      mobileVerification: _channel(
        present: mobile != null,
        verified: _bool(
            json, ['mobileVerified', 'phoneVerified', 'isMobileVerified']),
      ),
    );
  }

  static ChannelVerification _channel({
    required bool present,
    required bool? verified,
  }) {
    if (!present) return ChannelVerification.absent;
    // A missing flag is treated as UNVERIFIED, never verified. Deny by
    // default: the cost of re-asking for a code is an extra tap, and the cost
    // of assuming verification is letting an unproven channel through.
    return verified == true
        ? ChannelVerification.verified
        : ChannelVerification.unverified;
  }

  static bool? _bool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
    }
    return null;
  }

  Identity copyWith({
    String? email,
    String? mobileNumber,
    String? displayName,
    ChannelVerification? emailVerification,
    ChannelVerification? mobileVerification,
  }) =>
      Identity(
        uid: uid,
        email: email ?? this.email,
        mobileNumber: mobileNumber ?? this.mobileNumber,
        displayName: displayName ?? this.displayName,
        emailVerification: emailVerification ?? this.emailVerification,
        mobileVerification: mobileVerification ?? this.mobileVerification,
      );

  /// Diagnostics only, and deliberately free of contact details — an identity
  /// ends up in log lines and crash reports, which is not a place for an email
  /// address or a phone number.
  @override
  String toString() => 'Identity($uid, email: ${emailVerification.name}, '
      'mobile: ${mobileVerification.name})';
}
