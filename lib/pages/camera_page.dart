import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/face_detection/face_detection_service.dart';
import '../utils/isolate_utils.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({
    @required this.title,
    Key key,
  }) : super(key: key);

  final String title;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController _cameraController;
  List<CameraDescription> _cameras;
  CameraDescription _cameraDescription;

  bool _isRun;
  bool _predicting = false;
  bool _draw = false;
  Rect _bbox;

  FaceDetection _faceDetection;
  IsolateUtils _isolateUtils;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initStateAsync();
    super.initState();
  }

  void initStateAsync() async {
    WidgetsBinding.instance.addObserver(this);

    _isolateUtils = IsolateUtils();
    await _isolateUtils.start();

    await initCamera();

    _faceDetection = FaceDetection();
    _predicting = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(_cameraController.description);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  // camera
  Future<void> initCamera() async {
    _cameras = await availableCameras();
    _cameraDescription = _cameras[1];
    _isRun = false;
    onNewCameraSelected(_cameraDescription);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      // await _cameraController.dispose();
    }

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _cameraController.addListener(() {
      if (mounted) setState(() {});
      if (_cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${_cameraController.value.errorDescription}');
      }
    });

    try {
      await _cameraController.initialize().then((value) {
        if (!mounted) return;
      });
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _imageStreamToggle() {
    _isRun = !_isRun;
    if (_isRun) {
      _cameraController.startImageStream(onLatestImageAvailable);
    } else {
      _cameraController.stopImageStream();
    }
  }

  void _cameraDirectionToggle() {
    _isRun = false;
    if (_cameraController.description.lensDirection ==
        _cameras.first.lensDirection) {
      onNewCameraSelected(_cameras.last);
    } else {
      onNewCameraSelected(_cameras.first);
    }
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('message'),
      ),
    );
  }

  void _showCameraException(CameraException e) {
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  // Widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildCameraPreview(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Row _buildFloatingActionButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          onPressed: () {
            _cameraDirectionToggle();
            setState(() {
              _draw = false;
            });
          },
          color: Colors.white,
          iconSize: ScreenUtil().setWidth(30.0),
          icon: const Icon(
            Icons.cameraswitch,
          ),
        ),
        IconButton(
          onPressed: () {
            _imageStreamToggle();
            setState(() {
              _draw = !_draw;
            });
          },
          color: Colors.white,
          iconSize: ScreenUtil().setWidth(30.0),
          icon: const Icon(
            Icons.filter_center_focus,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: CameraPreview(_cameraController),
            ),
          ],
        ),
        _drawBoundingBox(),
      ],
    );
  }

  Widget _drawBoundingBox() {
    final screenSize = MediaQuery.of(context).size;
    var ratio = screenSize.width / _cameraController.value.previewSize.height;

    Color color = Colors.primaries[0];
    if (_bbox == null || !_draw) {
      return Container();
    } else {
      return Positioned(
          left: ratio * _bbox.left,
          top: ratio * _bbox.top,
          width: ratio * _bbox.width,
          height: ratio * _bbox.height,
          child: Container(
              decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
          )));
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        widget.title,
        style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil().setSp(28),
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> onLatestImageAvailable(CameraImage cameraImage) async {
    if (_faceDetection.interpreter != null) {
      // If previous inference has not completed then return
      if (_predicting || !_draw) {
        return;
      }

      setState(() {
        _predicting = true;
      });

      if (_draw) {
        var isolateData = IsolateData(
          cameraImage,
          _faceDetection.interpreter.address,
        );
        var inferenceResults = await inference(isolateData);

        _bbox = inferenceResults == null ? null : inferenceResults['bbox'];
      }

      setState(() {
        _predicting = false;
      });
    }
  }

  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    var responsePort = ReceivePort();
    _isolateUtils.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }
}
