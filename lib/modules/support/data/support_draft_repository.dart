import 'dart:convert';

import 'package:client/modules/support/domain/support_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupportDraftRepository {
  static const String _kPrefix = 'support_draft_';

  // Key is scoped by customer UID so drafts never cross accounts.
  String _key(String customerUid) => '$_kPrefix$customerUid';

  Future<SupportDraft?> loadDraft(String customerUid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(customerUid));
    if (raw == null || raw.isEmpty) return null;
    try {
      return SupportDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraft(String customerUid, SupportDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(customerUid), jsonEncode(draft.toJson()));
  }

  Future<void> clearDraft(String customerUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(customerUid));
  }

  // Clears ALL support drafts — called on logout for account isolation.
  Future<void> clearAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_kPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
