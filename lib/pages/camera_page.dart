import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  CameraImage _cameraImage;
  bool _isRun;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
    super.initState();
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

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final rearCamera = cameras[1];
    _isRun = false;
    onNewCameraSelected(rearCamera);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController.dispose();
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
      _cameraController.startImageStream((imageStream) {
        _cameraImage = imageStream;
      });
    } else {
      _cameraController.stopImageStream();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildCameraPreview(),
      floatingActionButton: IconButton(
        onPressed: () {
          setState(() {
            _imageStreamToggle();
          });
        },
        color: Colors.white,
        iconSize: ScreenUtil().setWidth(30.0),
        icon: const Icon(
          Icons.camera,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      children: [
        Expanded(
          child: CameraPreview(_cameraController),
        ),
      ],
    );
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
}
