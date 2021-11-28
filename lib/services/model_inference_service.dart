import 'dart:isolate';

import 'package:camera/camera.dart';

import '../utils/isolate_utils.dart';
import 'ai_model.dart';
import 'face_detection/face_detection_service.dart';
import 'face_mesh/face_mesh_service.dart';
import 'hands/hands_service.dart';
import 'pose/pose_service.dart';
import 'service_locator.dart';

enum Models {
  FaceDetection,
  FaceMesh,
  Hands,
  Pose,
}

class ModelInferenceService {
  late AiModel model;
  late Function handler;
  Map<String, dynamic>? inferenceResults;

  Future<Map<String, dynamic>?> inference({
    required IsolateUtils isolateUtils,
    required CameraImage cameraImage,
  }) async {
    final responsePort = ReceivePort();

    isolateUtils.sendMessage(
      handler: handler,
      params: {
        'cameraImage': cameraImage,
        'detectorAddress': model.getAddress,
      },
      sendPort: isolateUtils.sendPort,
      responsePort: responsePort,
    );

    inferenceResults = await responsePort.first;
    responsePort.close();
  }

  void setModelConfig(int index) {
    switch (Models.values[index]) {
      case Models.FaceDetection:
        model = locator<FaceDetection>();
        handler = runFaceDetector;
        break;
      case Models.FaceMesh:
        model = locator<FaceMesh>();
        handler = runFaceMesh;
        break;
      case Models.Hands:
        model = locator<Hands>();
        handler = runHandDetector;
        break;
      case Models.Pose:
        model = locator<Pose>();
        handler = runPoseEstimator;
        break;
    }
  }
}
