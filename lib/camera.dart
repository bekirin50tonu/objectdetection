import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite/tflite.dart';

class Camera extends StatefulWidget {
  final loadingWidget;
  const Camera({Key? key, this.loadingWidget}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller = null;
  int _selected = 0;
  String res = "";
  List<dynamic> predictions = [];

  @override
  void initState() {
    setupCameras();
    setupTfLite();
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    _controller!.dispose();
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      setupCameras();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera'),
      ),
      body: Container(
          child: _controller == null
              ? widget.loadingWidget
              : CameraPreview(_controller!)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          toggleCamera();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> setupCameras() async {
    await [
      Permission.camera,
    ].request();
    _cameras = await availableCameras();
    var controller = await selectCamera();
    setState(() => _controller = controller);
  }

  selectCamera() async {
    var controller =
        CameraController(_cameras[_selected], ResolutionPreset.low);
    return controller;
  }

  toggleCamera() async {
    int newSelected = (_selected + 1) % _cameras.length;
    _selected = newSelected;

    var controller = await selectCamera();
    setState(() => _controller = controller);
  }

  setupTfLite() async {
    res = await Tflite.loadModel(
            model: "assets/model.tflite",
            labels: "assets/classes.txt",
            numThreads: 1,
            isAsset: true,
            useGpuDelegate: false) ??
        "unsuccess";
  }

  predict() async {
    _controller!.startImageStream((image) => {recognitions(image)});
  }

  recognitions(img) async {
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 2, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true // defaults to true
        );
    setState(() {
      predictions = recognitions ?? [];
    });
  }
}
