enum ReviewVisibility {
  public,
  anonymousPublic,
  private;

  static ReviewVisibility fromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'ANONYMOUS_PUBLIC': return ReviewVisibility.anonymousPublic;
      case 'PRIVATE':          return ReviewVisibility.private;
      default:                 return ReviewVisibility.public;
    }
  }

  String get apiValue {
    switch (this) {
      case ReviewVisibility.public:          return 'PUBLIC';
      case ReviewVisibility.anonymousPublic: return 'ANONYMOUS_PUBLIC';
      case ReviewVisibility.private:         return 'PRIVATE';
    }
  }

  String get displayLabel {
    switch (this) {
      case ReviewVisibility.public:          return 'Public — your name is shown';
      case ReviewVisibility.anonymousPublic: return 'Anonymous — name hidden';
      case ReviewVisibility.private:         return 'Private — only visible to Servana';
    }
  }
}
