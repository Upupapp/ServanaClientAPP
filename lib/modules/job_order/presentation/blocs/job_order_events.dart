import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/modules/job_order/data/models/jo_photo_model.dart';
import 'package:client/modules/job_order/data/models/merchant_user.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

sealed class JOEvent {
  const JOEvent();

  List<Object> get props => [];
}

class LoadingJOEvent extends JOEvent {
  const LoadingJOEvent();

  @override
  List<Object> get props => ['LoadingJOEvent'];
}

class LoadJOEvent extends JOEvent {
  final String jobId;
  const LoadJOEvent(this.jobId);

  @override
  List<Object> get props => ['LoadJOEvent'];
}

class LoadedJOEvent extends JOEvent {
  const LoadedJOEvent();

  @override
  List<Object> get props => ['LoadedJOEvent'];
}

class AssignedPersonelJOEvent extends JOEvent {
  final MerchantUser personel;
  const AssignedPersonelJOEvent(this.personel);

  @override
  List<Object> get props => ['AssignedPersonelJOEvent', personel];
}

class UnassignedPersonelJOEvent extends JOEvent {
  final MerchantUser personel;
  const UnassignedPersonelJOEvent(this.personel);

  @override
  List<Object> get props => ['UnassignedPersonelJOEvent', personel];
}

class UpdatedPaymentMethodJOEvent extends JOEvent {
  final String paymentMethod;
  const UpdatedPaymentMethodJOEvent(this.paymentMethod);

  @override
  List<Object> get props => ['UpdatedPaymentMethodJOEvent', paymentMethod];
}

class DeployJOEvent extends JOEvent {
  final int jobId;
  const DeployJOEvent(this.jobId);

  @override
  List<Object> get props => ['DeployJOEvent', jobId];
}

class ReadyJOEvent extends JOEvent {
  final int jobId;
  const ReadyJOEvent(this.jobId);

  @override
  List<Object> get props => ['ReadyJOEvent', jobId];
}

class AddedPhotoJOEvent extends JOEvent {
  final JOPhotoModel photo;
  const AddedPhotoJOEvent(this.photo);

  @override
  List<Object> get props => ['AddedPhotoJOEvent', photo];
}

class AddOptionToJOEvent extends JOEvent {
  final StoreOptionItem optionItem;
  final String? jobOrderItemId;
  const AddOptionToJOEvent(this.optionItem, [this.jobOrderItemId]);

  @override
  List<Object> get props => ['AddOptionToJOEvent', optionItem];
}

class LoadServiceOptionsJOEven extends JOEvent {
  final int serviceId;
  const LoadServiceOptionsJOEven(this.serviceId);

  @override
  List<Object> get props => ['LoadServiceOptionsJOEven', serviceId];
}

class ConfirmAddOptionToJOEvent extends JOEvent {
  final List<StoreOptionItem> optionItems;
  final MerchantServiceModel service;
  const ConfirmAddOptionToJOEvent(this.service, this.optionItems);

  @override
  List<Object> get props => ['ConfirmAddOptionToJOEvent', service, optionItems];
}

class RemoveOptionToJOEvent extends JOEvent {
  final StoreOptionItem optionItem;
  final int? jobOrderOptionItemId;
  const RemoveOptionToJOEvent(
    this.optionItem, [
    this.jobOrderOptionItemId,
  ]);

  @override
  List<Object> get props => ['RemoveOptionToJOEvent', optionItem];
}

class StartedJOEvent extends JOEvent {
  final int jobId;
  const StartedJOEvent(this.jobId);

  @override
  List<Object> get props => ['StartedJOEvent', jobId];
}

class ResumedJOEvent extends JOEvent {
  final int jobId;
  const ResumedJOEvent(this.jobId);

  @override
  List<Object> get props => ['ResumedJOEvent', jobId];
}

class JoRequestEvent extends JOEvent {
  final String merchantId;
  final String merchantName;
  final DateTime schedule;
  final LatLong location;
  final String address;
  final String notes;
  const JoRequestEvent(this.merchantId, this.merchantName, this.schedule,
      this.location, this.address, this.notes);

  @override
  List<Object> get props => [
        'JoRequestEvent',
        merchantId,
        merchantName,
        schedule,
        location,
        address,
        notes
      ];
}

class PausedJOEvent extends JOEvent {
  final int jobId;
  const PausedJOEvent(this.jobId);

  @override
  List<Object> get props => ['PausedJOEvent', jobId];
}

class DoneJOEvent extends JOEvent {
  final int jobId;
  const DoneJOEvent(this.jobId);

  @override
  List<Object> get props => ['DoneJOEvent', jobId];
}

class CheckoutJOEvent extends JOEvent {
  final int jobId;
  const CheckoutJOEvent(this.jobId);

  @override
  List<Object> get props => ['CheckoutJOEvent', jobId];
}
