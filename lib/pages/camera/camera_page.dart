import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/data.dart';
import '../../services/model_inference_service.dart';
import '../../services/service_locator.dart';
import '../../utils/isolate_utils.dart';
import 'widget/model_camera_preview.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({
    required this.index,
    Key? key,
  }) : super(key: key);

  final int index;

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

  late IsolateUtils _isolateUtils;
  late ModelInferenceService _modelInferenceService;

  @override
  void initState() {
    _modelInferenceService = locator<ModelInferenceService>();
    _initStateAsync();
    super.initState();
  }

  void _initStateAsync() async {
    _isolateUtils = IsolateUtils();
    await _isolateUtils.initIsolate();
    await _initCamera();
    _predicting = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _isolateUtils.dispose();
    _modelInferenceService.inferenceResults = null;
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraDescription = _cameras[1];
    _isRun = false;
    _onNewCameraSelected(_cameraDescription);
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
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
      _showInSnackBar('Error: ${e.code}\n${e.description}');
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _imageStreamToggle;
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar,
        body: ModelCameraPreview(
          cameraController: _cameraController,
          index: widget.index,
          draw: _draw,
        ),
        floatingActionButton: _buildFloatingActionButton,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar get _buildAppBar => AppBar(
        title: Text(
          models[widget.index]['title']!,
          style: TextStyle(
              color: Colors.white,
              fontSize: ScreenUtil().setSp(28),
              fontWeight: FontWeight.bold),
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
      _cameraController!.startImageStream(
        (CameraImage cameraImage) async =>
            await _inference(cameraImage: cameraImage),
      );
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

  Future<void> _inference({required CameraImage cameraImage}) async {
    if (!mounted) return;

    if (_modelInferenceService.model.interpreter != null) {
      if (_predicting || !_draw) {
        return;
      }

      setState(() {
        _predicting = true;
      });

      if (_draw) {
        await _modelInferenceService.inference(
          isolateUtils: _isolateUtils,
          cameraImage: cameraImage,
        );
      }

      setState(() {
        _predicting = false;
      });
    }
  }
}
