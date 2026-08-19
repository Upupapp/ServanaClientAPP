/// Booking detail's caller for `BookingExperiencesRepository`.
///
/// ## Why this exists
///
/// The repository was registered in the injector and referenced by no screen
/// and no controller. Two capabilities — `bookingAdditionalWork` and
/// `bookingDisputes` — were declared complete against a surface a customer
/// could not enter.
///
/// ## The two halves are not equally ready, and this says so
///
/// **Change orders work today.** `GET /api/additional/booking/:bookingId`
/// exists on the legacy transport and the app had simply never called it. So a
/// provider could request extra work, the backend could record it, and the
/// customer had nowhere to see it. That is the half worth shipping.
///
/// **Disputes do not.** The only legacy dispute route is admin-only and a
/// customer token cannot use it, so `canOpenDispute` is false in every build
/// that exists. This controller therefore does not offer the action rather
/// than offering it and failing — a button that throws
/// `UnsupportedExperienceAction` is worse than no button, because the customer
/// has already decided to complain by the time they find out.
///
/// The moment `bookingDisputes` is enabled against a deployed `/api/v1`,
/// [canDispute] flips and the affordance appears with no further change here.
library;

import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_repository.dart';
import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:flutter/foundation.dart';

/// What booking detail should show for change orders right now.
sealed class ChangeOrdersState {
  const ChangeOrdersState();
}

class ChangeOrdersLoading extends ChangeOrdersState {
  const ChangeOrdersLoading();
}

/// The booking has change orders, or provably has none.
class ChangeOrdersReady extends ChangeOrdersState {
  const ChangeOrdersReady(this.requests);

  final List<AdditionalWorkRequest> requests;

  bool get isEmpty => requests.isEmpty;

  /// Change orders waiting on the CUSTOMER specifically.
  ///
  /// Only `WAITING_FOR_PAYMENT` qualifies. `PENDING_ADMIN_APPROVAL` and
  /// `WAITING_WORKER_APPROVAL` are also unfinished, but they are waiting on
  /// somebody else — telling a customer to act on those would be asking them
  /// for something they cannot give.
  List<AdditionalWorkRequest> get awaitingCustomer => requests
      .where((r) => r.status == AdditionalWorkStatus.waitingForPayment)
      .toList(growable: false);
}

/// They could not be read.
///
/// Booking detail renders everything else regardless — a change-order fetch
/// that fails must not cost the customer their booking.
class ChangeOrdersUnavailable extends ChangeOrdersState {
  const ChangeOrdersUnavailable(this.failure);

  final ApiFailure? failure;
}

class BookingExperiencesController extends ChangeNotifier {
  BookingExperiencesController(this._repository);

  final BookingExperiencesRepository _repository;

  ChangeOrdersState _state = const ChangeOrdersLoading();
  ChangeOrdersState get state => _state;

  bool _loading = false;

  /// Whether a customer can raise a dispute on this build's transport.
  ///
  /// False everywhere today. A UI must consult this before drawing the
  /// affordance; the repository throws rather than returning an empty category
  /// list, because a picker with no options and no explanation is worse.
  bool get canDispute => _repository.canOpenDispute;

  /// True when change orders are read from `/api/v1`. Diagnostics only.
  bool get isCanonical => _repository.additionalWorkIsCanonical;

  Future<void> load(String bookingId) async {
    if (_loading) return;
    _loading = true;
    try {
      final requests = await _repository.additionalWork(bookingId);
      _set(ChangeOrdersReady(requests));
    } on ApiFailure catch (failure) {
      _set(ChangeOrdersUnavailable(failure));
    } catch (_) {
      _set(const ChangeOrdersUnavailable(null));
    } finally {
      _loading = false;
    }
  }

  void _set(ChangeOrdersState next) {
    _state = next;
    notifyListeners();
  }
}
