import 'package:client/modules/job_order/data/models/jo_photo_model.dart';
import 'package:client/modules/job_order/data/models/merchant_user.dart';

sealed class JOState {
  const JOState();

  List<Object> get props => ['JOState'];
}

class InitialJOState extends JOState {
  const InitialJOState();

  @override
  List<Object> get props => ['InitialJOState'];
}

class UpdatedSelectedItems extends JOState {
  const UpdatedSelectedItems();

  @override
  List<Object> get props => ['UpdatedSelectedItems'];
}

class StartedJOState extends JOState {
  final String jobId;
  const StartedJOState(this.jobId);

  @override
  List<Object> get props => ['StartedJOState', jobId];
}

class InProgressJOState extends JOState {
  final String jobId;
  const InProgressJOState(this.jobId);

  @override
  List<Object> get props => ['InProgressJOState', jobId];
}

class PausedJOState extends JOState {
  final String jobId;
  const PausedJOState(this.jobId);

  @override
  List<Object> get props => ['PausedJOState', jobId];
}

class DoneJOState extends JOState {
  final String jobId;
  const DoneJOState(this.jobId);

  @override
  List<Object> get props => ['PausedJOState', jobId];
}

class PersonnelAssignedJOState extends JOState {
  final MerchantUser employee;
  const PersonnelAssignedJOState(this.employee);

  @override
  List<Object> get props => ['PausedJOState', employee];
}

class UpdatedPayementMethodJOState extends JOState {
  final String paymentMethod;
  const UpdatedPayementMethodJOState(this.paymentMethod);

  @override
  List<Object> get props => ['UpdatedPayementMethodJOState', paymentMethod];
}

class AddedPhotoJOState extends JOState {
  final JOPhotoModel photo;
  const AddedPhotoJOState(this.photo);

  @override
  List<Object> get props => ['AddedPhotoJOState', photo];
}

class PersonnelUnassignedJOState extends JOState {
  final MerchantUser employee;
  const PersonnelUnassignedJOState(this.employee);

  @override
  List<Object> get props => ['PausedJOState', employee];
}

class ReadyJOState extends JOState {
  final String jobId;
  const ReadyJOState(this.jobId);

  @override
  List<Object> get props => ['ReadyJOState', jobId];
}

class DeployedJOState extends JOState {
  final String jobId;
  const DeployedJOState(this.jobId);

  @override
  List<Object> get props => ['DeployedJOState', jobId];
}

class LoadedJOState extends JOState {
  const LoadedJOState();

  @override
  List<Object> get props => ['LoadedJOState'];
}

class LoadingJOState extends JOState {
  const LoadingJOState();

  @override
  List<Object> get props => ['LoadingJOState'];
}

class TopayJOState extends JOState {
  final String jobId;
  const TopayJOState(this.jobId);

  @override
  List<Object> get props => ['TopayJOState', jobId];
}

/// The submission did not reach the server.
///
/// There was no such state before, which is why a failed submission still
/// ended in [DoneJOState] with a "Job order submitted." snackbar and a local
/// placeholder booking the server had never heard of.
class FailedJOState extends JOState {
  final String message;
  const FailedJOState(this.message);

  @override
  List<Object> get props => ['FailedJOState', message];
}
