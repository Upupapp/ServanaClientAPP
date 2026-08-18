import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/adapters.dart';

part 'x_file_mod.g.dart';

@HiveType(typeId: 9)
class XFileMod extends XFile {
  @override
  @HiveField(91)
  final String path;

  @override
  @HiveField(92)
  final String? mimeType;

  @HiveField(93)
  final String? _name;

  /// The base implementation of `XFileBase.name` throws an
  /// [UnimplementedError] so we are overriding it to return a known
  /// [_name] value.
  @override
  String get name {
    if (_name != null) {
      return _name;
    }
    return super.name;
  }

  @HiveField(94)
  final int? _length;

  /// The base implementation of `XFileBase.length()` throws an
  /// [UnimplementedError] so we are overriding it to return a known
  /// [_length] value.
  @override
  Future<int> length() {
    return _length != null ? Future.value(_length) : super.length();
  }

  @HiveField(95)
  final Uint8List? bytes;

  @HiveField(96)
  final DateTime? _lastModified;

  /// The base implementation of `XFileBase.lastModified()` throws an
  /// [UnimplementedError] so we are overriding it to return a known
  /// [_lastModified] value.
  @override
  Future<DateTime> lastModified() {
    return _lastModified != null
        ? Future.value(_lastModified)
        : super.lastModified();
  }

  XFileMod(
    this.path, {
    this.mimeType,
    super.name,
    super.length,
    this.bytes,
    super.lastModified,
  })  : _name = name,
        _length = length,
        _lastModified = lastModified,
        super(
          path,
          mimeType: mimeType,
          bytes: bytes,
        );
}
