import 'package:client/modules/authentication/domain/identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deny by default', () {
    test('a present channel with no flag is UNVERIFIED, never verified', () {
      // The cost of re-asking for a code is a tap. The cost of assuming
      // verification is letting an unproven channel through.
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': 'a@b.c',
      });
      expect(identity.emailVerification, ChannelVerification.unverified);
      expect(identity.hasVerifiedChannel, isFalse);
    });

    test('an explicit false is unverified', () {
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': 'a@b.c',
        'emailVerified': false,
      });
      expect(identity.emailVerification, ChannelVerification.unverified);
    });

    test('only an explicit true verifies', () {
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': 'a@b.c',
        'emailVerified': true,
      });
      expect(identity.emailVerification, ChannelVerification.verified);
    });
  });

  group('email, mobile or both', () {
    test('an absent channel is absent, not unverified', () {
      // "No mobile number at all" and "unverified mobile number" lead to
      // different screens; collapsing them asks a customer to verify a number
      // they never gave.
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': 'a@b.c',
        'emailVerified': true,
      });
      expect(identity.mobileVerification, ChannelVerification.absent);
      expect(identity.pendingChannels, isEmpty);
    });

    test('a mobile-only verified account is fully verified', () {
      // Such an account must NOT be sent to an email OTP screen.
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'mobileNumber': '+639171234567',
        'mobileVerified': true,
      });
      expect(identity.hasVerifiedChannel, isTrue);
      expect(identity.emailVerification, ChannelVerification.absent);
      expect(identity.pendingChannels, isEmpty);
    });

    test('both present and unproven lists both as pending', () {
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': 'a@b.c',
        'mobileNumber': '+63917',
      });
      expect(identity.pendingChannels, <String>['email', 'mobile']);
    });
  });

  group('reads both the canonical and the legacy shape', () {
    test('canonical /me field names', () {
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': 'a@b.c',
        'mobileNumber': '+63',
        'displayName': 'Ana',
      });
      expect(identity.uid, 'u1');
      expect(identity.displayName, 'Ana');
    });

    test('legacy profile field names', () {
      final identity = Identity.fromJson(<String, dynamic>{
        'customerID': 'u1',
        'emailAddress': 'a@b.c',
        'phoneNumber': '+63',
        'fullname': 'Ana',
      });
      expect(identity.uid, 'u1');
      expect(identity.email, 'a@b.c');
      expect(identity.mobileNumber, '+63');
      expect(identity.displayName, 'Ana');
    });

    test('a string boolean is understood', () {
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': 'a@b.c',
        'emailVerified': 'true',
      });
      expect(identity.emailVerification, ChannelVerification.verified);
    });

    test('blank strings are treated as absent, not as empty values', () {
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': '   ',
      });
      expect(identity.email, isNull);
      expect(identity.emailVerification, ChannelVerification.absent);
    });
  });

  group('privacy', () {
    test('toString carries no contact details', () {
      // An identity ends up in log lines and crash reports.
      final identity = Identity.fromJson(<String, dynamic>{
        'uid': 'u1',
        'email': 'ana@example.com',
        'mobileNumber': '+639171234567',
        'displayName': 'Ana Cruz',
      });
      final text = identity.toString();
      expect(text, contains('u1'));
      expect(text, isNot(contains('ana@example.com')));
      expect(text, isNot(contains('639171234567')));
      expect(text, isNot(contains('Ana Cruz')));
    });
  });
}
