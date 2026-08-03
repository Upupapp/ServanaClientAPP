import 'package:client/common/data/models/merchant_model.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/job_order/data/models/merchant_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/common/data/models/job_order_item.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:client/modules/job_order/data/models/jo_details.dart';
import 'package:client/modules/job_order/data/models/jo_photo_model.dart';
import 'package:client/modules/job_order/domain/repositories/jo_repo.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ignore: depend_on_referenced_packages

class JobOrderBloc extends Bloc<JOEvent, JOState> {
  final JonOrderRepository repo;
  DateTime? timeStarted;
  DateTime? timePaused;
  DateTime? timeResumes;
  Stream? timer;
  String? paymentMethod;
  String? jobOrderId;
  JobOrderDetails? jobOrder;
  MerchantModel? merchant;
  List<JOPhotoModel> joPhotos = [];
  List<SelectedOption> selectedOptions = [];
  List<JobOrderItem> joServices = [];

  List<StoreOptionItem> toSelectOptions = [];

  List<MerchantUser> assignedPersonel = [];

  JobOrderBloc({required this.repo}) : super(const InitialJOState()) {
    on<JOEvent>((event, emit) async {
      switch (event) {
        case LoadingJOEvent():
          emit(const InitialJOState());

          /// todo
          break;
        case LoadedJOEvent():
          break;
        case AssignedPersonelJOEvent():
          break;
        case DeployJOEvent():
          break;
        case StartedJOEvent():
          break;
        case PausedJOEvent():
          onPausedJOEvent(event, emit);
          break;
        case DoneJOEvent():
          onDoneJOEvent(event, emit);
          break;
        case CheckoutJOEvent():
          break;
        case ResumedJOEvent():
          await onResumedJOEvent(event, emit);
          break;
        case ReadyJOEvent():
          break;
        case UnassignedPersonelJOEvent():
          break;
        case UpdatedPaymentMethodJOEvent():
          onUpdatedPaymentMethod(event, emit);
        case AddedPhotoJOEvent():
          onAddedPhotoJOEvent(event, emit);
        case AddOptionToJOEvent():
          await onAddOptionToJOEvent(event, emit);
        case RemoveOptionToJOEvent():
          onRemoveOptionToJOEvent(event, emit);
        case ConfirmAddOptionToJOEvent():
          onConfirmAddOptionToJOEvent(event, emit);
        case LoadServiceOptionsJOEven():
          onLoadServiceOptionsJOEven(event, emit);
        case LoadJOEvent():
          await onLoadLoadJOEvent(event, emit);
          break;
        case JoRequestEvent():
          await onJoRequested(event, emit);
          break;
      }
    });
  }

  Future<void> onLoadLoadJOEvent(LoadJOEvent event, Emitter emit) async {
    final prevState = state;
    emit(const LoadingJOState());
    jobOrderId = event.jobId;
    final joRes = await repo.getMerchantJobOrder(event.jobId);
    jobOrder = joRes;
    final res = await repo.getMerchantJobOrderItems(event.jobId);

    final merchantRes = await repo.getMerhcnatDetails(joRes?.merchantID ?? '');

    merchant = merchantRes;

    joServices.clear();
    joServices.addAll(res);
    final employeesRes = await repo.getJobOrderEmployees(event.jobId);
    assignedPersonel.clear();
    assignedPersonel.addAll(employeesRes);

    selectedOptions.clear();
    selectedOptions = joServices.fold(
        <SelectedOption>[],
        (previousValue, element) =>
            [...previousValue, ...element.selectedOptions]);

    switch (joRes?.jobOrderStatus) {
      case JobOrderStatus.accepted:
        emit(ReadyJOState(jobOrderId!));
        break;
      case JobOrderStatus.cancelled:
        break;
      case JobOrderStatus.completed:
        emit(DoneJOState(jobOrderId!));
        break;
      case JobOrderStatus.forReview:
        emit(ReadyJOState(jobOrderId!));
        break;
      case JobOrderStatus.inProgress:
        emit(InProgressJOState(jobOrderId!));
        break;
      case JobOrderStatus.inTransit:
        emit(DeployedJOState(jobOrderId!));
        break;
      default:
        emit(prevState);
    }
  }

  void onLoadServiceOptionsJOEven(
      LoadServiceOptionsJOEven event, Emitter emit) {
    final prevState = state;
    var preSelectedOptions = selectedOptions
        .where((element) => element.merchantServiceID == event.serviceId)
        .map(
          (e) => StoreOptionItem(
            merchantOptionID: e.merchantOptionItemID,
            merchantOptionItemName: e.merchantOptionItemName,
            amount: e.optionAmount,
            baseFair: 0,
          ),
        )
        .toList();
    toSelectOptions.clear();
    toSelectOptions.addAll(preSelectedOptions);
    emit(const UpdatedSelectedItems());
    emit(prevState);
  }

  void onConfirmAddOptionToJOEvent(
      ConfirmAddOptionToJOEvent event, Emitter emit) {
    final prevState = state;
    selectedOptions.removeWhere((element) =>
        element.merchantServiceID == event.service.merchantServiceID);
    selectedOptions.clear();
    selectedOptions.addAll(
      toSelectOptions.map(
        (e) => SelectedOption(
          jobOrderOptionItemID: 0,
          merchantOptionItemID: e.merchantOptionID,
          merchantServiceID: event.service.merchantServiceID,
          optionAmount: e.amount,
          merchantOptionItemName: e.merchantOptionItemName,
          quantity: 1,
          transportaion: e.baseFair,
        ),
      ),
    );
    toSelectOptions.clear();

    // bool markServiceFromMerchant = joServices
    //     .where(
    //       (element) =>
    //           (element.merchantServiceID == event.service.merchantServiceID &&
    //               !element.addedByMerchant),
    //     )
    //     .isEmpty;

    // joServices.removeWhere((element) =>
    //     element.merchantServiceID == event.service.merchantServiceID);

    var service = event.service;

    var joborder = JobOrderItem(
      selectedOptions: selectedOptions,
      serviceId: service.merchantServiceID.toString(),
      jobOrderItemID: 0,
      serviceName: service.merchantServiceName,
      quantity: 1,
      amount: service.amount.toDouble(),
      discount: 0,
      note: service.noteToCustomer,
      transportaion: service.baseFair.toDouble(),
    );

    joServices.add(joborder);

    emit(const UpdatedSelectedItems());
    emit(prevState);
  }

  double get subtotal {
    double serviceTotal = joServices.fold(
        0, (previousValue, element) => previousValue + element.amount);
    double optionTotal = toSelectOptions.fold(
        0, (previousValue, element) => previousValue + element.amount);

    double subtotal = serviceTotal + optionTotal;
    return subtotal;
  }

  double get transportation {
    double serviceTotal = joServices.fold(
        0, (previousValue, element) => previousValue + element.transportaion);
    double optionTotal = selectedOptions.fold(
        0, (previousValue, element) => previousValue + element.transportaion);

    double subtotal = serviceTotal + optionTotal;
    return subtotal;
  }

  double get total {
    // todo: subtract discount
    return (subtotal + transportation);
  }

  Future<void> onAddOptionToJOEvent(
      AddOptionToJOEvent event, Emitter emit) async {
    emit(const LoadingJOState());

    // bool markOptionFromMerchant = selectedOptions
    //     .where((element) =>
    //         element.merchantOptionItemID ==
    //         event.optionItem.merchantOptionItemID)
    //     .isEmpty;

    toSelectOptions.removeWhere(
      (element) =>
          element.merchantOptionItemID == event.optionItem.merchantOptionItemID,
    );

    var option = event.optionItem;

    toSelectOptions.add(option);
    emit(const UpdatedSelectedItems());
  }

  void onRemoveOptionToJOEvent(RemoveOptionToJOEvent event, Emitter emit) {
    emit(const LoadingJOState());

    toSelectOptions.removeWhere(
      (element) =>
          element.merchantOptionItemID == event.optionItem.merchantOptionItemID,
    );

    emit(const UpdatedSelectedItems());
  }

  bool isOptionSelected(StoreOptionItem option, [String? jobOrderItemId]) {
    return toSelectOptions
        .where((element) =>
            element.merchantOptionItemID == option.merchantOptionItemID)
        .isNotEmpty;
  }

  void onAddedPhotoJOEvent(AddedPhotoJOEvent event, Emitter emit) {
    final prevState = state;
    joPhotos.add(event.photo);
    emit(AddedPhotoJOState(event.photo));
    emit(prevState);
  }

  void onUpdatedPaymentMethod(UpdatedPaymentMethodJOEvent event, Emitter emit) {
    final prevState = state;
    paymentMethod = event.paymentMethod;
    emit(UpdatedPayementMethodJOState(event.paymentMethod));
    emit(prevState);
  }

  Future<void> onJoRequested(JoRequestEvent event, Emitter emit) async {
    emit(const LoadingJOState());

    // Try to insert to backend (may fail if backend is not available)
    repo.insertJobOrder(
      merchantId: event.merchantId,
      address: event.address,
      schedule: event.schedule,
      coords: LatLng(event.location.latitude, event.location.longitude),
      items: joServices,
      options: toSelectOptions,
    );

    // Optimistic UI: insert a local placeholder booking so the customer sees
    // their booking appear immediately without waiting for the next poll.
    // The placeholder ID starts with 'pending_' so downstream code can
    // distinguish it. loadBookings() will upsert the real record from the
    // backend, replacing this entry by ID when it arrives.
    final store = dpLocator<HomeStore>();

    final pendingId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final pendingNumber =
        'JO${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final serviceName = joServices.isNotEmpty
        ? joServices.map((s) => s.serviceName).join(', ')
        : 'Service';

    final totalAmount = joServices.fold<double>(
          0,
          (sum, item) => sum + item.amount + item.transportaion,
        ) +
        toSelectOptions.fold<double>(
          0,
          (sum, option) => sum + option.amount + option.baseFair,
        );

    final merchantName = event.merchantName;

    final pendingBooking = JobOrder(
      jobOrderID: pendingId,
      jobOrderNumber: pendingNumber,
      merchantName: merchantName,
      merchantID: event.merchantId,
      scheduleDate: event.schedule,
      jobOrderStatus: JobOrderStatus.forReview,
      jobOrderStatusToString: 'For Review',
      address: event.address,
      latitude: event.location.latitude,
      longitude: event.location.longitude,
      numberOfPersonnel: 1,
      distanceFromOffice: 0,
      merchantServiceName: serviceName,
      merchantServicePhoto: '',
      downPayment: 0,
      totalAmount: totalAmount,
      paymentType: 1,
      createdDate: DateTime.now(),
    );

    store.addBooking(pendingBooking);

    emit(const DoneJOState(""));
  }

  Future<void> onResumedJOEvent(ResumedJOEvent event, Emitter emit) async {
    timeResumes = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 100));
    emit(InProgressJOState(jobOrderId!));
  }

  void onPausedJOEvent(PausedJOEvent event, Emitter emit) {
    timePaused = DateTime.now();
    emit(PausedJOState(jobOrderId!));
  }

  void onDoneJOEvent(DoneJOEvent event, Emitter emit) {
    /// or donestate if cc or wallet
    timePaused = DateTime.now();

    repo.markAsCompleted(jobOrderId!);

    if (event.jobId == 1) {
      emit(DoneJOState(jobOrderId!));
    } else {
      emit(TopayJOState(jobOrderId!));
    }
  }
}
