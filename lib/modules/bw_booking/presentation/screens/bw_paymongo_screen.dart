import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Routed payload for [BwPaymongoScreen]. Carries the hosted-checkout URL
/// plus a payment-status checker the screen can poll without needing to know
/// which booking module spawned it (BW, Aircon, or post-hoc from bookings list).
class PaymongoCheckoutArgs {
  final String checkoutUrl;
  final Future<bool> Function() verifyPaymentStatus;

  const PaymongoCheckoutArgs({
    required this.checkoutUrl,
    required this.verifyPaymentStatus,
  });
}

/// PayMongo checkout screen.
/// On mobile: in-app WebView. On web: opens in a new browser tab.
/// Polls payment status every 5s and auto-pops when paid.
/// Stops polling after 30 minutes (timeout) or when disposed.
class BwPaymongoScreen extends StatefulWidget {
  static const String routeName = 'BwPaymongo';
  static const String route = 'BwPaymongo';

  final String checkoutUrl;
  final Future<bool> Function() verifyPaymentStatus;

  const BwPaymongoScreen({
    super.key,
    required this.checkoutUrl,
    required this.verifyPaymentStatus,
  });

  @override
  State<BwPaymongoScreen> createState() => _BwPaymongoScreenState();
}

class _BwPaymongoScreenState extends State<BwPaymongoScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _launchedExternal = false;
  bool _pollExpired = false;
  bool _isChecking = false;

  Timer? _pollTimer;
  DateTime? _pollStartTime;
  static const _pollInterval = Duration(seconds: 5);
  static const _pollTimeout = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    if (widget.checkoutUrl.isEmpty) {
      _isLoading = false;
      return;
    }

    if (kIsWeb) {
      _isLoading = false;
      _launchInBrowser();
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onNavigationRequest: (request) {
              final url = request.url.toLowerCase();
              if (url.contains('checkout_session') &&
                  (url.contains('status=paid') ||
                      url.contains('status=complete'))) {
                _stopPolling();
                if (mounted) Navigator.of(context).pop(true);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.checkoutUrl));
    }

    // Start polling payment status (only if we have a valid URL)
    if (widget.checkoutUrl.isNotEmpty) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _startPolling() {
    _pollStartTime = DateTime.now();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkPayment());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkPayment() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      // Timeout: stop polling after 30 minutes
      if (_pollStartTime != null &&
          DateTime.now().difference(_pollStartTime!) > _pollTimeout) {
        _stopPolling();
        if (mounted) setState(() => _pollExpired = true);
        return;
      }

      final paid = await widget.verifyPaymentStatus();
      if (paid && mounted) {
        _stopPolling();
        Navigator.of(context).pop(true);
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _manualCheck() async {
    final paid = await widget.verifyPaymentStatus();
    if (!mounted) return;
    if (paid) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment not yet confirmed. Please try again shortly.'),
        ),
      );
    }
  }

  Future<void> _launchInBrowser() async {
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
              Navigator.of(context).pop(false);
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
    if (widget.checkoutUrl.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: ColorPalette.danger),
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

    // Web: show "opened in new tab" message
    if (kIsWeb) {
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
              if (!_pollExpired) ...[
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
                  'Waiting for payment...',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText,
                    fontSize: 12,
                  ),
                ),
              ],
              if (_pollExpired) ...[
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
                    onPressed: _manualCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                      foregroundColor: ColorPalette.primaryButtonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'I\'ve Completed Payment',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!_launchedExternal)
                ElevatedButton.icon(
                  onPressed: _launchInBrowser,
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

    // Mobile: in-app WebView
    return Stack(
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
