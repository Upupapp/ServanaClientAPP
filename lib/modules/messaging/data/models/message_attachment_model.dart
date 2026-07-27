class MessageAttachmentModel {
  const MessageAttachmentModel({
    required this.id,
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
  });

  final int id;
  final String url;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;

  bool get isImage => mimeType.startsWith('image/');

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentModel(
      id: (json['id'] as num).toInt(),
      url: (json['url'] as String? ?? ''),
      fileName: (json['fileName'] as String? ?? json['file_name'] as String? ?? ''),
      mimeType: (json['mimeType'] as String? ?? json['mime_type'] as String? ?? ''),
      sizeBytes: (json['sizeBytes'] as num? ?? json['size_bytes'] as num? ?? 0).toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );
  }
}
