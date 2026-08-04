import 'dart:convert';

/// Per-customer, per-campaign-version record of what a customer has already
/// been shown (LAUNCHBANNER+ §4).
///
/// Deliberately a value object with no storage or presentation concerns: the
/// repository decides where it lives, the controller decides what it means.
/// The campaign spec's frequency rules are all expressible as pure functions of
/// this record plus a clock, which is what makes them testable without a device.
///
/// Two dismissals are tracked separately and must not be conflated:
///
///   [completedAt]            the customer chose the CTA — they engaged, and
///                            version 1 has served its purpose
///   [permanentlyDismissedAt] the customer chose Close — they actively declined
///
/// Both suppress the campaign forever, but they mean opposite things to anyone
/// reading the funnel, so collapsing them into one flag would destroy the only
/// signal that says whether the campaign worked.
class HomeCampaignState {
  const HomeCampaignState({
    required this.campaignId,
    required this.campaignVersion,
    this.impressionCount = 0,
    this.firstShownAt,
    this.lastShownAt,
    this.remindAfter,
    this.completedAt,
    this.permanentlyDismissedAt,
  });

  final String campaignId;
  final String campaignVersion;

  /// Verified impressions only — the campaign was actually rendered (§28).
  /// Scheduling, precaching and failed loads must never increment this.
  final int impressionCount;

  final DateTime? firstShownAt;
  final DateTime? lastShownAt;

  /// Set by "Remind me later", by system Back, and by barrier dismissal.
  /// Before this instant the campaign stays suppressed.
  final DateTime? remindAfter;

  /// The customer selected the primary CTA.
  final DateTime? completedAt;

  /// The customer explicitly chose Close.
  final DateTime? permanentlyDismissedAt;

  /// A customer who has engaged or declined is done with this version.
  bool get isFinished => completedAt != null || permanentlyDismissedAt != null;

  /// True while a "Remind me later" cooldown is still running.
  bool isInCooldown(DateTime now) =>
      remindAfter != null && now.isBefore(remindAfter!);

  HomeCampaignState copyWith({
    int? impressionCount,
    DateTime? firstShownAt,
    DateTime? lastShownAt,
    DateTime? remindAfter,
    DateTime? completedAt,
    DateTime? permanentlyDismissedAt,
  }) {
    return HomeCampaignState(
      campaignId: campaignId,
      campaignVersion: campaignVersion,
      impressionCount: impressionCount ?? this.impressionCount,
      firstShownAt: firstShownAt ?? this.firstShownAt,
      lastShownAt: lastShownAt ?? this.lastShownAt,
      remindAfter: remindAfter ?? this.remindAfter,
      completedAt: completedAt ?? this.completedAt,
      permanentlyDismissedAt:
          permanentlyDismissedAt ?? this.permanentlyDismissedAt,
    );
  }

  /// Records a verified impression.
  ///
  /// Clears [remindAfter]: the cooldown has served its purpose by the time an
  /// impression is granted, and leaving it set would make the NEXT eligibility
  /// check read a stale, already-expired timestamp.
  HomeCampaignState withImpression(DateTime now) {
    return HomeCampaignState(
      campaignId: campaignId,
      campaignVersion: campaignVersion,
      impressionCount: impressionCount + 1,
      firstShownAt: firstShownAt ?? now,
      lastShownAt: now,
      remindAfter: null,
      completedAt: completedAt,
      permanentlyDismissedAt: permanentlyDismissedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'campaignVersion': campaignVersion,
        'impressionCount': impressionCount,
        'firstShownAt': firstShownAt?.toIso8601String(),
        'lastShownAt': lastShownAt?.toIso8601String(),
        'remindAfter': remindAfter?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'permanentlyDismissedAt': permanentlyDismissedAt?.toIso8601String(),
      };

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  factory HomeCampaignState.fromJson(Map<String, dynamic> json) {
    return HomeCampaignState(
      campaignId: json['campaignId'] as String? ?? '',
      campaignVersion: json['campaignVersion'] as String? ?? '',
      impressionCount: (json['impressionCount'] as num?)?.toInt() ?? 0,
      firstShownAt: _date(json['firstShownAt']),
      lastShownAt: _date(json['lastShownAt']),
      remindAfter: _date(json['remindAfter']),
      completedAt: _date(json['completedAt']),
      permanentlyDismissedAt: _date(json['permanentlyDismissedAt']),
    );
  }

  String encode() => jsonEncode(toJson());

  /// Decodes persisted state, returning null rather than throwing.
  ///
  /// Corrupt or truncated state must degrade to "this customer has no history"
  /// — which shows the campaign again — rather than crash Home. §29 requires
  /// campaign failures never to block Home, and that includes this path.
  static HomeCampaignState? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return HomeCampaignState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'HomeCampaignState($campaignId v$campaignVersion, '
      'impressions=$impressionCount, remindAfter=$remindAfter, '
      'completed=$completedAt, dismissed=$permanentlyDismissedAt)';
}
