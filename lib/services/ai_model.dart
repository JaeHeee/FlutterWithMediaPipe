import 'package:equatable/equatable.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

// ignore: must_be_immutable
abstract class AiModel extends Equatable {
  AiModel();

  final outputShapes = <List<int>>[];
  final outputTypes = <TfLiteType>[];

  Interpreter? getInterpreter;

  @override
  List<Object> get props => [];

  int get getAddress;

  Future<void> loadModel();
  TensorImage getProcessedImage(TensorImage inputImage);
  Map<String, dynamic>? predict(image_lib.Image image);
}
