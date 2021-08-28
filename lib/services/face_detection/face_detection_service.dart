import 'dart:io';
import 'dart:ui';

import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'anchors.dart';
import 'generate_anchors.dart';
import 'non_maximum_suppression.dart';
import 'options.dart';
import 'process.dart';

class FaceDetection {
  static const String MODEL_FILE_NAME =
      'models/face_detection_short_range.tflite';
  static const int INPUT_SIZE = 128;
  static const double THRESHOLD = 0.7;

  InterpreterOptions _interpreterOptions;
  Interpreter _interpreter;
  ImageProcessor _imageProcessor;

  List<List<int>> _outputShapes;
  List<TfLiteType> _outputTypes;

  OptionsFace options = OptionsFace(
      numClasses: 1,
      numBoxes: 896,
      numCoords: 16,
      keypointCoordOffset: 4,
      ignoreClasses: [],
      scoreClippingThresh: 100.0,
      minScoreThresh: 0.75,
      numKeypoints: 6,
      numValuesPerKeypoint: 2,
      reverseOutputOrder: true,
      boxCoordOffset: 0,
      xScale: 128,
      yScale: 128,
      hScale: 128,
      wScale: 128);

  AnchorOption anchors = AnchorOption(
      inputSizeHeight: 128,
      inputSizeWidth: 128,
      minScale: 0.1484375,
      maxScale: 0.75,
      anchorOffsetX: 0.5,
      anchorOffsetY: 0.5,
      numLayers: 4,
      featureMapHeight: [],
      featureMapWidth: [],
      strides: [8, 16, 16, 16],
      aspectRatios: [1.0],
      reduceBoxesInLowestLayer: false,
      interpolatedScaleAspectRatio: 1.0,
      fixedAnchorSize: true);

  List<Anchor> _anchors;

  Interpreter get interpreter => _interpreter;

  FaceDetection({Interpreter interpreter}) {
    _loadModel(interpreter: interpreter);
  }

  void _loadModel({Interpreter interpreter}) async {
    try {
      _interpreterOptions = InterpreterOptions();

      _anchors = generateAnchors(anchors);
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            MODEL_FILE_NAME,
            options: _interpreterOptions,
          );

      var outputTensors = _interpreter.getOutputTensors();
      _outputShapes = [];
      _outputTypes = [];
      outputTensors.forEach((tensor) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      });
    } catch (e) {
      print('Error while creating interpreter: $e');
    }
  }

  TensorImage _getProcessedImage(TensorImage inputImage) {
    _imageProcessor ??= ImageProcessorBuilder()
        .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
        .add(NormalizeOp(127.5, 127.5))
        .build();

    inputImage = _imageProcessor.process(inputImage);
    return inputImage;
  }

  Map<String, dynamic> predict(image_lib.Image image) {
    if (_interpreter == null) {
      print('Interpreter not initialized');
      return null;
    }

    if (Platform.isAndroid) {
      image = image_lib.copyRotate(image, -90);
      image = image_lib.flipHorizontal(image);
    }
    var tensorImage = TensorImage(TfLiteType.float32);
    tensorImage.loadImage(image);
    var inputImage = _getProcessedImage(tensorImage);

    TensorBuffer outputFaces = TensorBufferFloat(_outputShapes[0]);
    TensorBuffer outputScores = TensorBufferFloat(_outputShapes[1]);

    var inputs = <Object>[inputImage.buffer];

    var outputs = <int, Object>{
      0: outputFaces.buffer,
      1: outputScores.buffer,
    };

    // run inference
    _interpreter.runForMultipleInputs(inputs, outputs);

    var rawBoxes = outputFaces.getDoubleList();
    var rawScores = outputScores.getDoubleList();
    var detections = process(
        options: options,
        rawScores: rawScores,
        rawBoxes: rawBoxes,
        anchors: _anchors);

    detections = nonMaximumSuppression(detections, THRESHOLD);
    if (detections.isEmpty) {
      return null;
    }

    var rectFaces = <Map<String, dynamic>>[];

    for (var detection in detections) {
      Rect bbox;
      var score = detection.score;
      if (score > THRESHOLD) {
        bbox = Rect.fromLTRB(
          inputImage.width * detection.xMin,
          inputImage.height * detection.yMin,
          inputImage.width * detection.width,
          inputImage.height * detection.height,
        );

        bbox = _imageProcessor.inverseTransformRect(
            bbox, image.height, image.width);

        bbox = bbox.translate(0, image.height * 0.1);
      }
      rectFaces.add({'bbox': bbox, 'score': score});
    }
    rectFaces.sort((a, b) => b['score'].compareTo(a['score']));

    return rectFaces[0];
  }
}
