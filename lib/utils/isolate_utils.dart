import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../services/face_detection/face_detection_service.dart';
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
        var faceDetection = FaceDetection(
          interpreter: Interpreter.fromAddress(isolateData.interpreterAddress),
        );

        var image = ImageUtils.convertCameraImage(isolateData.cameraImage);
        if (Platform.isAndroid) {
          image = image_lib.copyRotate(image, 90);
        }

        var results = faceDetection.predict(image);
        isolateData.responsePort.send(results);
      }
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  CameraImage cameraImage;
  int interpreterAddress;
  SendPort responsePort;

  IsolateData(
    this.cameraImage,
    this.interpreterAddress,
  );
}
