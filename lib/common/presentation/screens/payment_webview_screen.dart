import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Serialisable route args for [PaymentWebViewScreen].
///
/// Uses [bookingId] to verify payment via the backend — no closure injected,
/// which means this object is safe to restore after process death or deep-link.
class PaymentScreenArgs {
  const PaymentScreenArgs({
    required this.bookingId,
    required this.checkoutUrl,
  });

  final int bookingId;

  /// PayMongo hosted-checkout URL returned by POST /api/{id}/paymongo/create.
  final String checkoutUrl;
}

/// Hardened PayMongo checkout screen (replaces the legacy BwPaymongoScreen).
///
/// Security rules enforced here:
/// - Checkout URL must be HTTPS.
/// - WebView navigation is allowed ONLY to [_approvedHosts].
/// - Redirect detection parses the URI properly; it does not rely on broad
///   substring checks.
/// - Redirect is treated only as a trigger to verify with the backend —
///   never as proof of payment by itself.
/// - No auth tokens or secrets are injected into the WebView.
/// - Payment status is always confirmed server-side via GET /api/{bookingId}.
class PaymentWebViewScreen extends StatefulWidget {
  static const String routeName = 'PaymentWebView';
  static const String route = 'PaymentWebView';

  const PaymentWebViewScreen({
    super.key,
    required this.bookingId,
    required this.checkoutUrl,
  });

  final int bookingId;
  final String checkoutUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  // Only these hosts may receive WebView navigation without being blocked.
  static const _approvedHosts = {
    'checkout.paymongo.com',
    'api.paymongo.com',
    'paymongo.com',
    'www.paymongo.com',
    // Servana callback endpoints
    'app.servana.com.ph',
    'servana.com.ph',
    'api.servana.com.ph',
  };

  // Approved callback paths that signal a payment redirect.
  static const _successPaths = {'/payment/success', '/checkout/success'};
  static const _cancelPaths = {'/payment/cancel', '/checkout/cancel'};

  WebViewController? _webController;
  bool _isPageLoading = true;
  bool _launchedExternal = false;
  bool _pollExpired = false;
  bool _isChecking = false;
  bool _dismissed = false;

  Timer? _pollTimer;
  DateTime? _pollStart;
  static const _pollInterval = Duration(seconds: 5);
  static const _pollTimeout = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    final url = widget.checkoutUrl;

    if (url.isEmpty) {
      _isPageLoading = false;
      return;
    }

    // Validate URL scheme — only HTTPS is permitted.
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      _isPageLoading = false;
      return;
    }

    if (kIsWeb) {
      _isPageLoading = false;
      _openInBrowser();
    } else {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isPageLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isPageLoading = false);
          },
          onNavigationRequest: _handleNavigation,
        ))
        ..loadRequest(uri);
    }

    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    // Only HTTPS is allowed in the WebView.
    if (uri.scheme != 'https') {
      // External app schemes (mailto:, tel:, etc.) — open externally.
      if (uri.scheme == 'mailto' || uri.scheme == 'tel') {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return NavigationDecision.prevent;
    }

    final host = uri.host.toLowerCase();

    // Check for a payment-success callback from an approved host.
    if (_approvedHosts.any((h) => host == h || host.endsWith('.$h'))) {
      final path = uri.path.toLowerCase();
      if (_successPaths.any((p) => path.startsWith(p))) {
        // Redirect is a signal only — verify with backend before closing.
        _stopPolling();
        _verifyAndClose();
        return NavigationDecision.prevent;
      }
      if (_cancelPaths.any((p) => path.startsWith(p))) {
        _stopPolling();
        if (mounted && !_dismissed) {
          _dismissed = true;
          Navigator.of(context).pop(false);
        }
        return NavigationDecision.prevent;
      }
      // Approved host navigating within the checkout — allow.
      return NavigationDecision.navigate;
    }

    // Block all other hosts.
    return NavigationDecision.prevent;
  }

  void _startPolling() {
    _pollStart = DateTime.now();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkPayment());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkPayment() async {
    if (_isChecking || _dismissed) return;
    if (_pollStart != null &&
        DateTime.now().difference(_pollStart!) > _pollTimeout) {
      _stopPolling();
      if (mounted) setState(() => _pollExpired = true);
      return;
    }
    _isChecking = true;
    try {
      final paid = await _verifyPayment();
      if (paid && mounted && !_dismissed) {
        _stopPolling();
        _dismissed = true;
        Navigator.of(context).pop(true);
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _verifyPayment() async {
    try {
      final api = dpLocator<ServanaApiClient>();
      final res = await api.getBooking(widget.bookingId);
      final booking = res['booking'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;
      final status = BookingStatusMapper.fromString(
        booking['paymentStatus']?.toString() ?? booking['status']?.toString(),
      );
      return status == BookingStatus.paid ||
          status == BookingStatus.confirmed ||
          status == BookingStatus.awaitingAssignment ||
          status == BookingStatus.assigned;
    } catch (_) {
      return false;
    }
  }

  Future<void> _verifyAndClose() async {
    final paid = await _verifyPayment();
    if (!mounted || _dismissed) return;
    _dismissed = true;
    Navigator.of(context).pop(paid);
  }

  Future<void> _manualCheck() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final paid = await _verifyPayment();
      if (!mounted) return;
      if (paid && !_dismissed) {
        _dismissed = true;
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Payment not yet confirmed. Please wait a moment and try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) setState(() => _launchedExternal = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Payment',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: ColorPalette.primaryColorDark,
        foregroundColor: ColorPalette.primaryText,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              _stopPolling();
              if (!_dismissed) {
                _dismissed = true;
                Navigator.of(context).pop(false);
              }
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                color: ColorPalette.primaryText,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final uri = Uri.tryParse(widget.checkoutUrl);
    if (widget.checkoutUrl.isEmpty || uri == null || uri.scheme != 'https') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: ColorPalette.danger),
              const SizedBox(height: 12),
              Text(
                'Payment URL is not available. Please go back and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: ColorPalette.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (kIsWeb) {
      return _WebFallback(
        pollExpired: _pollExpired,
        isChecking: _isChecking,
        launchedExternal: _launchedExternal,
        onOpenBrowser: _openInBrowser,
        onManualCheck: _manualCheck,
      );
    }

    return Stack(
      children: [
        if (_webController != null)
          WebViewWidget(controller: _webController!),
        if (_isPageLoading)
          const Center(child: CircularProgressIndicator()),
        if (_pollExpired)
          _ManualCheckBanner(onTap: _manualCheck, isChecking: _isChecking),
      ],
    );
  }
}

class _WebFallback extends StatelessWidget {
  const _WebFallback({
    required this.pollExpired,
    required this.isChecking,
    required this.launchedExternal,
    required this.onOpenBrowser,
    required this.onManualCheck,
  });

  final bool pollExpired;
  final bool isChecking;
  final bool launchedExternal;
  final VoidCallback onOpenBrowser;
  final VoidCallback onManualCheck;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new_rounded,
                size: 56, color: ColorPalette.primaryColorDark),
            const SizedBox(height: 16),
            Text(
              'Payment opened in a new tab',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: ColorPalette.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your payment in the new tab.\nThis page will update automatically once payment is confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.accentText,
              ),
            ),
            const SizedBox(height: 24),
            if (!pollExpired) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for payment confirmation…',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: ColorPalette.accentText,
                  fontSize: 12,
                ),
              ),
            ],
            if (pollExpired) ...[
              Text(
                'Auto-check timed out.',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: ColorPalette.accentText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isChecking ? null : onManualCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColor,
                    foregroundColor: ColorPalette.primaryButtonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          "Check Payment Status",
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!launchedExternal)
              ElevatedButton.icon(
                onPressed: onOpenBrowser,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Payment Page'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryColorDark,
                  foregroundColor: ColorPalette.primaryText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ManualCheckBanner extends StatelessWidget {
  const _ManualCheckBanner({required this.onTap, required this.isChecking});
  final VoidCallback onTap;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isChecking ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primaryColor,
                foregroundColor: ColorPalette.primaryButtonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Check Payment Status',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
