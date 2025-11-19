import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'ONESIGNAL_APP_ID')
  static const String oneSignalAppId = _Env.oneSignalAppId;

  @EnviedField(varName: 'ONESIGNAL_REST_API_KEY')
  static const String oneSignalRestApiKey = _Env.oneSignalRestApiKey;

  @EnviedField(varName: 'CLOUDINARY_CLOUD_NAME', optional: true, defaultValue: 'dexm0l8os')
  static const String cloudinaryCloudName = _Env.cloudinaryCloudName;

  @EnviedField(varName: 'CLOUDINARY_UPLOAD_PRESET', optional: true, defaultValue: 'DIURecycle')
  static const String cloudinaryUploadPreset = _Env.cloudinaryUploadPreset;
}

