import 'package:tflite_flutter/tflite_flutter.dart';

class GpuDelegateSetting {
  static final gpuDelegateV2 = GpuDelegateV2(
      options: GpuDelegateOptionsV2(
    false,
    TfLiteGpuInferenceUsage.fastSingleAnswer,
    TfLiteGpuInferencePriority.minLatency,
    TfLiteGpuInferencePriority.auto,
    TfLiteGpuInferencePriority.auto,
  ));

  static final gpuDelegate = GpuDelegate(
    options: GpuDelegateOptions(true, TFLGpuDelegateWaitType.active),
  );
}
