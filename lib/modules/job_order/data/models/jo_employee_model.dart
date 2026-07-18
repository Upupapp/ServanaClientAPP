import 'package:freezed_annotation/freezed_annotation.dart';

part 'jo_employee_model.freezed.dart';
part 'jo_employee_model.g.dart';

@Freezed(fromJson: true, toJson: true)
class JOEmployeeModel with _$JOEmployeeModel {
  const factory JOEmployeeModel({
    required final String name,
    required final String contactNo,
    final String? photoURL,
  }) = _JOEmployeeModel;

  factory JOEmployeeModel.fromJson(Map<String, dynamic> json) =>
      _$JOEmployeeModelFromJson(json);
}
