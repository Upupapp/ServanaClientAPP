import 'dart:io';

import 'package:client/common/services/onboarding_state_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('onboarding_hive_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  test('default status is notSeen when no value has been persisted', () async {
    final status = await OnboardingStateService.getStatus();
    expect(status, OnboardingStatus.notSeen);
  });

  test('hasCompletedOrSkipped returns false by default', () async {
    expect(await OnboardingStateService.hasCompletedOrSkipped(), isFalse);
  });

  // ── Round-trip writes ─────────────────────────────────────────────────────

  test('setStatus(completed) is read back correctly', () async {
    await OnboardingStateService.setStatus(OnboardingStatus.completed);
    expect(
        await OnboardingStateService.getStatus(), OnboardingStatus.completed);
  });

  test('setStatus(skippedToBrowse) is read back correctly', () async {
    await OnboardingStateService.setStatus(OnboardingStatus.skippedToBrowse);
    expect(
      await OnboardingStateService.getStatus(),
      OnboardingStatus.skippedToBrowse,
    );
  });

  test('setStatus(inProgress) is read back correctly', () async {
    await OnboardingStateService.setStatus(OnboardingStatus.inProgress);
    expect(
        await OnboardingStateService.getStatus(), OnboardingStatus.inProgress);
  });

  test('status can be overwritten — last write wins', () async {
    await OnboardingStateService.setStatus(OnboardingStatus.inProgress);
    await OnboardingStateService.setStatus(OnboardingStatus.completed);
    expect(
        await OnboardingStateService.getStatus(), OnboardingStatus.completed);
  });

  // ── hasCompletedOrSkipped ─────────────────────────────────────────────────

  test('hasCompletedOrSkipped returns true for completed', () async {
    await OnboardingStateService.setStatus(OnboardingStatus.completed);
    expect(await OnboardingStateService.hasCompletedOrSkipped(), isTrue);
  });

  test('hasCompletedOrSkipped returns true for skippedToBrowse', () async {
    await OnboardingStateService.setStatus(OnboardingStatus.skippedToBrowse);
    expect(await OnboardingStateService.hasCompletedOrSkipped(), isTrue);
  });

  test('hasCompletedOrSkipped returns false for inProgress', () async {
    await OnboardingStateService.setStatus(OnboardingStatus.inProgress);
    expect(await OnboardingStateService.hasCompletedOrSkipped(), isFalse);
  });

  test('hasCompletedOrSkipped returns false for notSeen', () async {
    await OnboardingStateService.setStatus(OnboardingStatus.notSeen);
    expect(await OnboardingStateService.hasCompletedOrSkipped(), isFalse);
  });
}
