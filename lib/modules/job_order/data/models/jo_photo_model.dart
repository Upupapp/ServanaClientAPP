// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

part 'jo_photo_model.freezed.dart';
part 'jo_photo_model.g.dart';

@Freezed(fromJson: true, toJson: true)
class JOPhotoModel with _$JOPhotoModel {
  const factory JOPhotoModel({
    @JsonKey(includeFromJson: false, includeToJson: false) XFile? photoFile,
    @Default(false) final bool isFromMerchant,
  }) = _JOPhotoModel;
}
