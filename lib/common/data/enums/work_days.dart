import 'package:json_annotation/json_annotation.dart';

enum WeekDay {
  @JsonValue(1)
  sunday,
  @JsonValue(2)
  monday,
  @JsonValue(3)
  tuesday,
  @JsonValue(4)
  wednesday,
  @JsonValue(5)
  thursday,
  @JsonValue(6)
  friday,
  @JsonValue(7)
  saturday,
  @JsonValue(0)
  unknown;

  static WeekDay parse(int val) {
    return WeekDay.values
        .firstWhere((e) => e.value == val, orElse: () => unknown);
  }
}

extension WeekDayExtension on WeekDay {
  static const values = {
    WeekDay.sunday: 1,
    WeekDay.monday: 2,
    WeekDay.tuesday: 3,
    WeekDay.wednesday: 4,
    WeekDay.thursday: 5,
    WeekDay.friday: 6,
    WeekDay.saturday: 7,
    WeekDay.unknown: 0,
  };

  static const abbrs = {
    WeekDay.sunday: "Sun",
    WeekDay.monday: "Mon",
    WeekDay.tuesday: "Tue",
    WeekDay.wednesday: "Wed",
    WeekDay.thursday: "Thu",
    WeekDay.friday: "Fri",
    WeekDay.saturday: "Sat",
    WeekDay.unknown: "N/A",
  };

  String? get abbr => abbrs[this];

  int get value => values[this] ?? 0;
}
