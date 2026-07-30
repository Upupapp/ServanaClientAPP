enum SafetyIncidentSeverity {
  general,
  minor,
  moderate,
  serious,
  immediateDanger;

  String get apiKey {
    switch (this) {
      case general:
        return 'level_0';
      case minor:
        return 'level_1';
      case moderate:
        return 'level_2';
      case serious:
        return 'level_3';
      case immediateDanger:
        return 'level_4';
    }
  }

  String get label {
    switch (this) {
      case general:
        return 'General concern';
      case minor:
        return 'Minor concern';
      case moderate:
        return 'Moderate concern';
      case serious:
        return 'Serious concern';
      case immediateDanger:
        return 'Immediate danger';
    }
  }
}

enum SafetyIncidentCategory {
  harassment,
  physicalThreat,
  sexualHarassment,
  unsafeEnvironment,
  unsafeRequest,
  propertyDamage,
  injury,
  medicalEvent,
  other;

  String get apiKey {
    switch (this) {
      case harassment:
        return 'harassment';
      case physicalThreat:
        return 'physical_threat';
      case sexualHarassment:
        return 'sexual_harassment';
      case unsafeEnvironment:
        return 'unsafe_environment';
      case unsafeRequest:
        return 'unsafe_request';
      case propertyDamage:
        return 'property_damage';
      case injury:
        return 'injury';
      case medicalEvent:
        return 'medical_event';
      case other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case harassment:
        return 'Harassment';
      case physicalThreat:
        return 'Physical threat';
      case sexualHarassment:
        return 'Sexual harassment';
      case unsafeEnvironment:
        return 'Unsafe environment';
      case unsafeRequest:
        return 'Unsafe or inappropriate request';
      case propertyDamage:
        return 'Property damage';
      case injury:
        return 'Injury';
      case medicalEvent:
        return 'Medical event';
      case other:
        return 'Other safety concern';
    }
  }
}

class SafetyIncident {
  final String caseKey;
  final String? safeReference;
  final SafetyIncidentCategory category;
  final SafetyIncidentSeverity severity;
  final String state;
  final String? bookingId;
  final DateTime? reportedAt;
  final DateTime? updatedAt;
  final bool isOpen;

  const SafetyIncident({
    required this.caseKey,
    this.safeReference,
    required this.category,
    required this.severity,
    required this.state,
    this.bookingId,
    this.reportedAt,
    this.updatedAt,
    required this.isOpen,
  });

  factory SafetyIncident.fromMap(Map<String, dynamic> m) {
    SafetyIncidentCategory cat;
    switch (m['category'] as String?) {
      case 'harassment':
        cat = SafetyIncidentCategory.harassment;
        break;
      case 'physical_threat':
        cat = SafetyIncidentCategory.physicalThreat;
        break;
      case 'sexual_harassment':
        cat = SafetyIncidentCategory.sexualHarassment;
        break;
      case 'unsafe_environment':
        cat = SafetyIncidentCategory.unsafeEnvironment;
        break;
      case 'unsafe_request':
        cat = SafetyIncidentCategory.unsafeRequest;
        break;
      case 'property_damage':
        cat = SafetyIncidentCategory.propertyDamage;
        break;
      case 'injury':
        cat = SafetyIncidentCategory.injury;
        break;
      case 'medical_event':
        cat = SafetyIncidentCategory.medicalEvent;
        break;
      default:
        cat = SafetyIncidentCategory.other;
    }
    SafetyIncidentSeverity sev;
    switch (m['severity'] as String?) {
      case 'level_4':
        sev = SafetyIncidentSeverity.immediateDanger;
        break;
      case 'level_3':
        sev = SafetyIncidentSeverity.serious;
        break;
      case 'level_2':
        sev = SafetyIncidentSeverity.moderate;
        break;
      case 'level_1':
        sev = SafetyIncidentSeverity.minor;
        break;
      default:
        sev = SafetyIncidentSeverity.general;
    }
    return SafetyIncident(
      caseKey: m['caseKey']?.toString() ?? '',
      safeReference: m['safeReference'] as String?,
      category: cat,
      severity: sev,
      state: (m['state'] as String?) ?? 'submitted',
      bookingId: m['bookingId'] as String?,
      reportedAt: m['reportedAt'] != null
          ? DateTime.tryParse(m['reportedAt'].toString())
          : null,
      updatedAt: m['updatedAt'] != null
          ? DateTime.tryParse(m['updatedAt'].toString())
          : null,
      isOpen: (m['isOpen'] as bool?) ?? true,
    );
  }
}

class EmergencyLine {
  final String label;
  final String number;
  final String dialLabel;
  final String description;

  const EmergencyLine({
    required this.label,
    required this.number,
    required this.dialLabel,
    required this.description,
  });

  factory EmergencyLine.fromMap(Map<String, dynamic> m) => EmergencyLine(
        label: m['label']?.toString() ?? '',
        number: m['number']?.toString() ?? '',
        dialLabel: m['dialLabel']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
      );
}
