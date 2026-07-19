import 'package:client/common/config/app_config.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:flutter/material.dart';

const String kDefaultPlaceholderAsset = 'assets/images/Default.png';

bool _isHttpUrl(String? url) {
  final u = url?.trim();
  if (u == null || u.isEmpty) return false;
  final parsed = Uri.tryParse(u);
  if (parsed == null) return false;
  return parsed.hasScheme &&
      (parsed.scheme == 'http' || parsed.scheme == 'https');
}

bool _allowNetworkImages() {
  // In white-label/mock builds we want zero external calls by default.
  try {
    return !dpLocator<AppConfig>().mockBackend;
  } catch (_) {
    return false;
  }
}

ImageProvider appImageProvider(
  String? url, {
  String placeholderAsset = kDefaultPlaceholderAsset,
}) {
  final u = url?.trim();
  if (_allowNetworkImages() && _isHttpUrl(u)) {
    return NetworkImage(u!);
  }
  return AssetImage(placeholderAsset);
}

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderAsset = kDefaultPlaceholderAsset,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String placeholderAsset;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    if (_allowNetworkImages() && _isHttpUrl(u)) {
      return Image.network(
        u!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(
          placeholderAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    return Image.asset(
      placeholderAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
