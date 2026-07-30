import 'package:client/modules/store_items/data/models/store_option_items.dart';

sealed class AddOptionState {
  const AddOptionState();

  List<Object?> get props => const [];
}

class InitialAddOptionState extends AddOptionState {
  const InitialAddOptionState();

  @override
  List<Object?> get props => ["InitialAddOptionState"];
}

class LoadingAddOptionState extends AddOptionState {
  const LoadingAddOptionState();

  @override
  List<Object?> get props => ["LoadingAddOptionState"];
}

class LoadedAddOptionState extends AddOptionState {
  const LoadedAddOptionState();

  @override
  List<Object?> get props => ["LoadedAddOptionState"];
}

class AddedOptionItemState extends AddOptionState {
  final StoreOptionItem item;
  const AddedOptionItemState({required this.item});

  @override
  List<Object?> get props => ["AddedOptionItemState", item];
}

class SubmittedAddOptionState extends AddOptionState {
  const SubmittedAddOptionState();

  @override
  List<Object?> get props => ["SubmittedAddOptionState"];
}
