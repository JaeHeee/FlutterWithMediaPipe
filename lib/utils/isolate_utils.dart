import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter_with_mediapipe/services/face_detection/face_detection_service.dart';
import 'package:flutter_with_mediapipe/services/hands/hands_service.dart';
import 'package:flutter_with_mediapipe/services/pose/pose_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../services/face_mesh/face_mesh_service.dart';
import 'image_utils.dart';

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String DEBUG_NAME = 'InferenceIsolate';

  final ReceivePort _receivePort = ReceivePort();

  Isolate _isolate;
  SendPort _sendPort;

  SendPort get sendPort => _sendPort;
  Isolate get isolate => _isolate;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    _sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final IsolateData isolateData in port) {
      if (isolateData != null) {
        var results = _predict(
          modelName: isolateData.model,
          isolateData: isolateData,
        );

        isolateData.responsePort.send(results);
      }
    }
  }

  static Map<String, dynamic> _predict({
    String modelName,
    IsolateData isolateData,
  }) {
    var model;
    switch (modelName) {
      case 'face_detection':
        model = FaceDetection(
          interpreter: Interpreter.fromAddress(isolateData.interpreterAddress),
        );
        break;
      case 'face_mesh':
        model = FaceMesh(
          interpreter: Interpreter.fromAddress(isolateData.interpreterAddress),
        );
        break;
      case 'hands':
        model = Hands(
          interpreter: Interpreter.fromAddress(isolateData.interpreterAddress),
        );
        break;
      case 'pose_landmark':
        model = Pose(
          interpreter: Interpreter.fromAddress(isolateData.interpreterAddress),
        );
        break;
    }
    var image = ImageUtils.convertCameraImage(isolateData.cameraImage);
    var results = model.predict(image);

    return results;
  }
}

class IsolateData {
  CameraImage cameraImage;
  int interpreterAddress;
  String model;
  SendPort responsePort;

  IsolateData(
    this.cameraImage,
    this.interpreterAddress,
    this.model,
  );
}
