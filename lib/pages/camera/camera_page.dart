import 'dart:isolate';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/face_detection/face_detection_service.dart';
import '../../services/face_mesh/face_mesh_painter.dart';
import '../../services/face_mesh/face_mesh_service.dart';
import '../../services/hands/hands_painter.dart';
import '../../services/hands/hands_service.dart';
import '../../services/pose/pose_painter.dart';
import '../../services/pose/pose_service.dart';
import '../../utils/isolate_utils.dart';
import 'widget/model_painter.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({
    required this.title,
    required this.modelName,
    Key? key,
  }) : super(key: key);

  final String title;
  final String modelName;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late CameraDescription _cameraDescription;

  late bool _isRun;
  bool _predicting = false;
  bool _draw = false;

  late double _ratio;
  late Size _screenSize;
  Rect? _bbox;
  List<Offset>? _faceLandmarks;
  List<Offset>? _handLandmarks;
  List<Offset>? _poseLandmarks;

  late FaceDetection _faceDetection;
  late FaceMesh _faceMesh;
  late Hands _hands;
  late Pose _pose;

  late IsolateUtils _isolateUtils;

  @override
  void initState() {
    _initStateAsync();
    super.initState();
  }

  void _initStateAsync() async {
    _isolateUtils = IsolateUtils();
    await _isolateUtils.initIsolate();

    await _initCamera();

    switch (widget.modelName) {
      case 'face_detection':
        _faceDetection = FaceDetection();
        break;
      case 'face_mesh':
        _faceMesh = FaceMesh();
        break;
      case 'hands':
        _hands = Hands();
        break;
      case 'pose_landmark':
        _pose = Pose();
        break;
    }

    _predicting = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(_cameraController!.description);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _isolateUtils.dispose();
    super.dispose();
  }

  // camera
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraDescription = _cameras[1];
    _isRun = false;
    _onNewCameraSelected(_cameraDescription);
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _cameraController!.addListener(() {
      if (mounted) setState(() {});
      if (_cameraController!.value.hasError) {
        _showInSnackBar(
            'Camera error ${_cameraController!.value.errorDescription}');
      }
    });

    try {
      await _cameraController!.initialize().then((value) {
        if (!mounted) return;
      });
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showCameraException(CameraException e) {
    _showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  // Widget
  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        _imageStreamToggle;
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar,
        body: _buildCameraPreview,
        floatingActionButton: _buildFloatingActionButton,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar get _buildAppBar => AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil().setSp(28),
              fontWeight: FontWeight.bold),
        ),
      );

  Widget get _buildCameraPreview {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    _ratio = _screenSize.width / _cameraController!.value.previewSize!.height;

    return Stack(
      children: [
        CameraPreview(_cameraController!),
        _drawBoundingBox,
        _drawLandmarks,
        _drawHands,
        _drawPose,
      ],
    );
  }

  Widget get _drawBoundingBox {
    Color color = Colors.primaries[0];
    _bbox ??= Rect.zero;

    return Visibility(
      visible: _bbox != null && _draw,
      child: Positioned(
        left: _ratio * _bbox!.left,
        top: _ratio * _bbox!.top,
        width: _ratio * _bbox!.width,
        height: _ratio * _bbox!.height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
          ),
        ),
      ),
    );
  }

  Widget get _drawLandmarks => Visibility(
        visible: _faceLandmarks != null && _draw,
        child: ModelPainter(
          customPainter: FaceMeshPainter(
            points: _faceLandmarks ?? [],
            ratio: _ratio,
          ),
        ),
      );

  Widget get _drawHands => Visibility(
        visible: _handLandmarks != null && _draw,
        child: ModelPainter(
          customPainter: HandsPainter(
            points: _handLandmarks ?? [],
            ratio: _ratio,
          ),
        ),
      );

  Widget get _drawPose => Visibility(
        visible: _poseLandmarks != null && _draw,
        child: ModelPainter(
          customPainter: PosePainter(
            points: _poseLandmarks ?? [],
            ratio: _ratio,
          ),
        ),
      );

  Row get _buildFloatingActionButton => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () => _cameraDirectionToggle,
            color: Colors.white,
            iconSize: ScreenUtil().setWidth(30.0),
            icon: const Icon(
              Icons.cameraswitch,
            ),
          ),
          IconButton(
            onPressed: () => _imageStreamToggle,
            color: Colors.white,
            iconSize: ScreenUtil().setWidth(30.0),
            icon: const Icon(
              Icons.filter_center_focus,
            ),
          ),
        ],
      );

  void get _imageStreamToggle {
    setState(() {
      _draw = !_draw;
    });

    _isRun = !_isRun;
    if (_isRun) {
      _cameraController!.startImageStream(_onLatestImageAvailable);
    } else {
      _cameraController!.stopImageStream();
    }
  }

  void get _cameraDirectionToggle {
    setState(() {
      _draw = false;
    });
    _isRun = false;
    if (_cameraController!.description.lensDirection ==
        _cameras.first.lensDirection) {
      _onNewCameraSelected(_cameras.last);
    } else {
      _onNewCameraSelected(_cameras.first);
    }
  }

  Future<void> _onLatestImageAvailable(CameraImage cameraImage) async {
    switch (widget.modelName) {
      case 'face_detection':
        await _inference(
          model: _faceDetection,
          handler: runFaceDetector,
          cameraImage: cameraImage,
        );
        break;
      case 'face_mesh':
        await _inference(
          model: _faceMesh,
          handler: runFaceMesh,
          cameraImage: cameraImage,
        );
        break;
      case 'hands':
        await _inference(
          model: _hands,
          handler: runHandDetector,
          cameraImage: cameraImage,
        );
        break;
      case 'pose_landmark':
        await _inference(
          model: _pose,
          handler: runPoseEstimator,
          cameraImage: cameraImage,
        );
        break;
    }
  }

  Future<void> _inference({
    dynamic model,
    required Function handler,
    required CameraImage cameraImage,
  }) async {
    if (model.interpreter != null) {
      if (_predicting || !_draw) {
        return;
      }

      setState(() {
        _predicting = true;
      });

      if (_draw) {
        final params = {
          'cameraImage': cameraImage,
          'detectorAddress': model.getAddress,
        };
        final inferenceResults = await _sendPort(
          handler: handler,
          params: params,
        );
        final isInferenceNull = inferenceResults == null;

        switch (widget.modelName) {
          case 'face_detection':
            _bbox = isInferenceNull ? null : inferenceResults!['bbox'];
            break;
          case 'face_mesh':
            _faceLandmarks =
                isInferenceNull ? null : inferenceResults!['point'];
            break;
          case 'hands':
            _handLandmarks =
                isInferenceNull ? null : inferenceResults!['point'];
            break;
          case 'pose_landmark':
            _poseLandmarks =
                isInferenceNull ? null : inferenceResults!['point'];
            break;
        }
      }

      setState(() {
        _predicting = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _sendPort({
    required Function handler,
    required Map<String, dynamic> params,
  }) async {
    final responsePort = ReceivePort();

    _isolateUtils.sendMessage(
      handler: handler,
      params: params,
      sendPort: _isolateUtils.sendPort,
      responsePort: responsePort,
    );

    final results = await responsePort.first;
    responsePort.close();

    return results;
  }
}
