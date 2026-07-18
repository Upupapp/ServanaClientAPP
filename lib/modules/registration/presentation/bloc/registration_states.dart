import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/registration/data/resources/form_state.dart';

sealed class RegistrationState {
  final RegistrationFormModel? registration;
  final FormState? formState;
  const RegistrationState({this.registration, this.formState});

  // @override
  List<Object> get props => ['RegistrationFormModel'];
}

class RegistrationInitialState extends RegistrationState {
  const RegistrationInitialState({
    super.registration,
    super.formState,
  });

  @override
  List<Object> get props => ['RegistrationInitialState'];
}

class RegistrationNormalState extends RegistrationState {
  const RegistrationNormalState({
    required RegistrationFormModel registration,
    required FormState formState,
  }) : super(registration: registration, formState: formState);

  @override
  List<Object> get props => ['RegistrationNormalState'];
}

class RegistrationLoadedState extends RegistrationState {
  const RegistrationLoadedState({
    RegistrationFormModel registration = const RegistrationFormModel(),
  }) : super(registration: registration);

  @override
  List<Object> get props => ['RegistrationLoadedState', registration!.hashCode];
}

class RegistrationLoadingState extends RegistrationState {
  const RegistrationLoadingState();

  @override
  List<Object> get props => ['RegistrationLoadingState'];
}

class RegistrationSubmittedState extends RegistrationState {
  const RegistrationSubmittedState({
    required RegistrationFormModel registration,
    required FormState formState,
  }) : super(registration: registration, formState: formState);

  @override
  List<Object> get props =>
      ['RegistrationSubmittedState', registration!, formState!];
}

class RegistrationFormValidState extends RegistrationState {
  const RegistrationFormValidState({
    required RegistrationFormModel registration,
    required FormState formState,
  }) : super(registration: registration, formState: formState);

  @override
  List<Object> get props =>
      ['RegistrationSubmittedState', registration!, formState!];
}

class RegistrationSubmittedFailedState extends RegistrationState {
  final String error;

  const RegistrationSubmittedFailedState({
    required RegistrationFormModel registration,
    required this.error,
    required FormState formState,
  }) : super(formState: formState, registration: registration);

  @override
  List<Object> get props =>
      ['RegistrationSubmittedFailedState', registration!, error, formState!];
}

class RegistrationValidationFailedState extends RegistrationState {
  const RegistrationValidationFailedState({
    required RegistrationFormModel registration,
    required FormState formState,
  }) : super(registration: registration, formState: formState);

  @override
  List<Object> get props =>
      ['RegistrationValidationFailedState', registration!, formState!];
}

class RegistrationValidationResetState extends RegistrationState {
  const RegistrationValidationResetState({
    required RegistrationFormModel registration,
    required FormState formState,
  }) : super(registration: registration, formState: formState);

  @override
  List<Object> get props =>
      ['RegistrationValidationResetState', registration!, formState!];
}

class RegistrationSavedToCacheState extends RegistrationState {
  const RegistrationSavedToCacheState();

  @override
  List<Object> get props => ['RegistrationSavedToCacheState'];
}

class RegistrationSavedToCacheFailedState extends RegistrationState {
  final String error;
  const RegistrationSavedToCacheFailedState({
    required this.error,
    required RegistrationFormModel registration,
    required FormState formState,
  }) : super(registration: registration, formState: formState);

  @override
  List<Object> get props =>
      ['RegistrationSavedToCacheFailedState', registration!, formState!, error];
}

class RegistrationLoadedFromCacheState extends RegistrationState {
  const RegistrationLoadedFromCacheState({
    required RegistrationFormModel registration,
  }) : super(registration: registration);

  @override
  List<Object> get props => ['RegistrationLoadedFromCacheState', registration!];
}

class RegistrationLoadedFromCacheFailedState extends RegistrationState {
  final String error;
  const RegistrationLoadedFromCacheFailedState({
    required this.error,
  });

  @override
  List<Object> get props => ['RegistrationLoadedFromCacheFailedState', error];
}

class ResendVerificationLoadingState extends RegistrationState {
  const ResendVerificationLoadingState();

  @override
  List<Object> get props => ['ResendVerificationLoadingState'];
}

class ResendVerificationSuccessState extends RegistrationState {
  final String message;
  const ResendVerificationSuccessState({required this.message});

  @override
  List<Object> get props => ['ResendVerificationSuccessState', message];
}

class ResendVerificationFailedState extends RegistrationState {
  final String error;
  const ResendVerificationFailedState({required this.error});

  @override
  List<Object> get props => ['ResendVerificationFailedState', error];
}
