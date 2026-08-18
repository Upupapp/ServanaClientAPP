/// The contract both identity transports satisfy.
///
/// `IdentityCompatibilityDataSource` implements it over the legacy routes;
/// `IdentityCanonicalDataSource` implements it over `/api/v1`.
/// `IdentityRepository` holds this type, so the choice is one line there and
/// invisible to `AuthenticationBloc`, to `EmailVerificationScreen` and to every
/// widget.
///
/// ## What is deliberately NOT here
///
/// **Sign-in.** The customer app authenticates through
/// `POST /api/auth/customer-firebase-login`, and TAB 01 established from the
/// backend's own migration matrix that this route is `ROLE_SPECIFIC` and
/// explicitly **not collapsed** into `POST /api/v1/auth/login`. Its
/// link-collision contract is a 200 carrying `status: "failed"` and no token,
/// because the installed app throws on any non-2xx before reading the body and
/// fires `onUnauthorized` on 401 — either would show "session expired" to
/// somebody who has no session yet. Changing that shape is a client release.
///
/// So sign-in stays on the legacy path in every configuration, and this
/// interface covers only the operations that genuinely have a canonical
/// successor. Putting `login` here would let a build claim a migration the
/// backend has documented as impossible.
///
/// The same reasoning excludes `register`: the customer app creates accounts
/// through `RegistrationRepository` → `Backend.registerCustomer`, which is a
/// different payload from `POST /api/v1/auth/register` and is entangled with
/// the multi-step registration form. That is a TAB-04-and-later concern.
library;

import 'package:client/modules/authentication/domain/identity.dart';

abstract interface class IdentityDataSource {
  /// Who am I? Derived server-side from the bearer token.
  ///
  /// Takes no identifier by design — see `Identity`. A method that accepted a
  /// uid would be a method that could be asked about somebody else.
  Future<Identity> fetchIdentity();

  /// Sends (or re-sends) an email verification code to [email].
  ///
  /// Unauthenticated by necessity: a customer who has not verified cannot sign
  /// in to obtain a token, so the backend looks the OTP row up by address.
  Future<void> resendEmailVerification(String email);

  /// Proves ownership of [email] with [otp].
  Future<void> verifyEmail({required String email, required String otp});

  /// Claims the mobile number proven by [idToken].
  ///
  /// **The proof is Firebase's, not ours.** [idToken] must be a Firebase ID
  /// token whose sign-in provider is `phone`, or which has a phone credential
  /// linked — and Firebase only issues one after running its OWN SMS OTP. The
  /// backend has no SMS sender and does not pretend to verify a number itself:
  /// `auth.verifyMobile` verifies the token, reads the number off the
  /// credential and refuses anything that does not prove one.
  ///
  /// This used to take a `mobileNumber` and an `otp` the app had collected,
  /// which no transport could ever satisfy — the canonical one would answer
  /// `VALIDATION_FAILED` and the legacy one has no route at all. Carrying the
  /// wrong two arguments made an unimplementable call look implemented, so the
  /// signature now says what v1 actually wants.
  ///
  /// Acquiring the token is a Firebase phone-auth flow and belongs with the
  /// screen that will run it. There is no such screen yet, and there is
  /// deliberately not one here: the compatibility transport cannot serve this
  /// on any shipped build, so a UI would fail at the moment of use.
  Future<void> verifyMobile({required String idToken});

  /// Starts a password reset for [email].
  Future<void> forgotPassword(String email);

  /// Completes a password reset.
  Future<void> resetPassword(
      {required String token, required String newPassword});

  /// Revokes the session server-side. Best-effort by contract: the caller
  /// clears local state regardless of the outcome.
  Future<void> logout();
}

/// Thrown by a transport asked for something it genuinely cannot do.
///
/// Distinct from a network failure on purpose. "This build has no route for
/// mobile verification" is a deterministic fact about the transport, not a
/// transient condition, and retrying it forever would be wrong.
class UnsupportedTransportOperation implements Exception {
  const UnsupportedTransportOperation(this.operation, this.reason);

  final String operation;
  final String reason;

  @override
  String toString() => 'UnsupportedTransportOperation($operation): $reason';
}
