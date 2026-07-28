import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/tracking/application/tracking_controller.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:client/modules/tracking/domain/tracking_args.dart';
import 'package:client/modules/tracking/presentation/widgets/tracking_eta_card.dart';
import 'package:client/modules/tracking/presentation/widgets/tracking_map.dart';
import 'package:client/modules/tracking/presentation/widgets/tracking_provider_card.dart';
import 'package:client/modules/tracking/presentation/widgets/tracking_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

/// Full-screen live tracking experience for an active booking.
///
/// Entry points:
///   - [BookingDetailScreen] "Track Provider" button when status is enRoute /
///     arrived / inProgress
///   - Deep link: `/bookings/:bookingId/track`
///
/// The screen polls the backend for location + status updates every 10 s.
/// It auto-closes when the booking reaches a terminal state.
///
/// SECURITY:
///   - Every displayed coordinate comes from [BookingTrackingState.providerLocation]
///     which is populated only from a verified backend response.
///   - No coordinates are synthesised, animated, or extrapolated.
///   - ETA is always shown with an "estimated at assignment" disclaimer
///     (TRACK-GAP-003).
class LiveTrackingScreen extends StatefulWidget {
  static const String routeName = 'LiveTracking';
  static const String route = 'track'; // nested under '/bookings/:bookingId/'

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
    this.args,
  });

  final String bookingId;
  final TrackingArgs? args;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final TrackingController _controller;

  @override
  void initState() {
    super.initState();
    // Factory registration means each LiveTrackingScreen gets its own controller.
    _controller = dpLocator<TrackingController>();
    final args = widget.args;
    _controller.startTracking(
      bookingId: widget.bookingId,
      workerUid: args?.workerUid,
      workerName: args?.workerName,
      workerPhone: args?.workerPhone,
      serviceLatitude: args?.serviceLatitude,
      serviceLongitude: args?.serviceLongitude,
      serviceAddress: args?.serviceAddress,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openChat() {
    context.push('/bookings/${widget.bookingId}/messages');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Observer(
        builder: (_) {
          final state = _controller.trackingState;
          final isLoading = _controller.isLoading;
          final error = _controller.error;

          // Auto-close on terminal state (booking completed, cancelled, etc.)
          if (state != null && state.isTerminal && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showTerminalDialog(state);
              }
            });
          }

          if (isLoading && state == null) {
            return _LoadingBody();
          }

          if (error != null && state == null) {
            return _ErrorBody(
              error: error,
              onRetry: _controller.refresh,
            );
          }

          if (state == null) {
            return _LoadingBody();
          }

          return _TrackingBody(
            state: state,
            controller: _controller,
            onChatTap: _openChat,
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Observer(
        builder: (_) {
          final state = _controller.trackingState;
          return Text(
            state?.providerName != null
                ? 'Tracking ${state!.providerName}'
                : 'Tracking Provider',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          );
        },
      ),
      backgroundColor: ColorPalette.primaryColorDark,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Observer(
          builder: (_) => _controller.isPolling
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _controller.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
        ),
      ],
    );
  }

  void _showTerminalDialog(BookingTrackingState state) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          'Booking Update',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Your booking is now ${state.bookingStatus.name}. '
          'The tracking screen will close.',
          style: TextStyle(fontFamily: FontPalette.primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({
    required this.state,
    required this.controller,
    required this.onChatTap,
  });

  final BookingTrackingState state;
  final TrackingController controller;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map fills the top portion.
        TrackingMap(state: state),

        // Scrollable detail panel.
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            color: ColorPalette.primaryColorDark,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // Status banner.
                  TrackingStatusBar(
                    status: state.bookingStatus,
                    isPolling: controller.isPolling,
                  ),

                  const SizedBox(height: 12),

                  // ETA card — shown only when ETA is available.
                  if (state.eta != null)
                    TrackingEtaCard(
                      eta: state.eta,
                      freshness: state.freshness,
                      bookingStatus: state.bookingStatus.name,
                    ),

                  if (state.eta != null) const SizedBox(height: 12),

                  // Provider card with message + call actions.
                  TrackingProviderCard(
                    state: state,
                    onMessageTap: onChatTap,
                  ),

                  const SizedBox(height: 16),

                  // Address row.
                  if (state.serviceAddress.isNotEmpty)
                    _AddressRow(address: state.serviceAddress),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address});
  final String address;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 18,
            color: ColorPalette.accentText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                color: ColorPalette.accentText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: ColorPalette.primaryColorDark),
          const SizedBox(height: 16),
          Text(
            'Loading tracking…',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.accentText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.danger,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primaryColorDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
