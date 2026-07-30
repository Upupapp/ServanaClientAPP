import 'package:client/common/data/models/merchant_service.dart';

sealed class EditItemEvent {
  const EditItemEvent();

  List<Object?> get props => const [];
}

class InitEditItemEvent extends EditItemEvent {
  final MerchantServiceModel item;
  final List<SelectionOption> selectedOptions;
  const InitEditItemEvent({
    required this.item,
    required this.selectedOptions,
  });

  @override
  // TODO: implement props
  List<Object?> get props => ["InitEditItemEvent", item, selectedOptions];
}

class EditedItemEvent extends EditItemEvent {
  final MerchantServiceModel item;
  const EditedItemEvent({required this.item});

  @override
  // TODO: implement props
  List<Object?> get props => ["EditedItemEvent", item];
}

class ToogleEditItemEvent extends EditItemEvent {
  final bool value;
  const ToogleEditItemEvent({required this.value});

  @override
  // TODO: implement props
  List<Object?> get props => ["ToogleItemEvent", value];
}
