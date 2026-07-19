/// Maps a service name to an asset thumbnail. Used until the backend ships
/// per-service photo URLs. Keep most-specific tokens first (deep facial before
/// facial, foot massage before massage).
String serviceImageAsset(String name) {
  final n = name.toLowerCase();
  if (n.contains('manicure') || n.contains('pedicure') || n.contains('nail')) {
    return 'assets/images/services/manicure_image.png';
  }
  if (n.contains('hair')) {
    return 'assets/images/services/hair_dry_image.png';
  }
  if (n.contains('foot') && n.contains('massage')) {
    return 'assets/images/services/foot_massage_generic_image.png';
  }
  if (n.contains('massage')) {
    return 'assets/images/services/massage_generic_image.png';
  }
  if (n.contains('deep') && n.contains('facial')) {
    return 'assets/images/services/deep_facial_image.png';
  }
  if (n.contains('facial')) {
    return 'assets/images/services/basic_facial_image.png';
  }
  return 'assets/images/home/book_image.png';
}
