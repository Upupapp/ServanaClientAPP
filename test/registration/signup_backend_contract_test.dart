import 'dart:convert';

import 'package:client/common/data/backend/http_backend.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/profile/presentation/screens/email_verification_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const registration = RegistrationFormModel(
    ownerName: 'Juan Dela Cruz',
    ownerEmail: 'juan@example.com',
    ownerPhoneNo: '09171234567',
    ownerPassword: 'StrongPass1!',
  );

  test('mobile signup sends the backend contract and parses wrapped response',
      () async {
    late Map<String, dynamic> requestBody;
    final backend = HttpBackend(
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/signup');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'success': true,
              'userId': 'new-user',
              'message': 'OTP sent to juan@example.com',
            },
          }),
          200,
        );
      }),
    );

    final result = await backend.registerCustomer(registration);

    expect(result.isSuccess, isTrue);
    expect(result.message, 'OTP sent to juan@example.com');
    expect(requestBody, containsPair('platform', 'mobile'));
    expect(requestBody, containsPair('role', 3));
    expect(requestBody, containsPair('firstName', 'Juan'));
    expect(requestBody, containsPair('lastName', 'Dela Cruz'));
  });

  test('legacy root signup response remains supported', () async {
    final backend = HttpBackend(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async => http.Response(
            jsonEncode({'success': true, 'message': 'Legacy success'}),
            200,
          )),
    );

    final result = await backend.registerCustomer(registration);

    expect(result.isSuccess, isTrue);
    expect(result.message, 'Legacy success');
  });

  test('explicit wrapped failure is not converted into success', () async {
    final backend = HttpBackend(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'status': 'success',
              'data': {'success': false, 'message': 'Signup rejected'},
            }),
            200,
          )),
    );

    final result = await backend.registerCustomer(registration);

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Signup rejected');
  });

  test('legacy status-only error is not converted into profile success',
      () async {
    final backend = HttpBackend(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async => http.Response(
            jsonEncode({'status': 'error', 'message': 'Profile not created'}),
            200,
          )),
    );

    final result = await backend.registerCustomer(registration);

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Profile not created');
  });

  test('signup OTP destination carries email out of the URL', () {
    const args = SignupEmailVerificationArgs(email: 'juan@example.com');

    expect(EmailVerificationScreen.route, '/signup/verify-email');
    expect(EmailVerificationScreen.route, isNot(contains(args.email)));
    expect(args.email, 'juan@example.com');
  });
}
