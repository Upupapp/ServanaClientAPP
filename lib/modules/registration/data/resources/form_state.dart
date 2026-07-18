import 'package:client/modules/registration/data/models/reg_form_error_model.dart';

sealed class FormState {
  final RegFormErrorModel? formError;

  const FormState({
    this.formError,
  });

  bool get hasError => formError != null;
}

class FormValid extends FormState {
  const FormValid() : super();
}

class FormInvalid extends FormState {
  const FormInvalid(RegFormErrorModel formError) : super(formError: formError);
}
