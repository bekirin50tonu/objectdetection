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
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
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
          child: Column(
        children: [
          buildBody(),
          Text(predictions.length.toString() ?? (res ?? ""))
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selected != _cameras.length) {
            _selected++;
          } else {
            _selected = 0;
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget buildBody() {
    if (_controller == null) {
      if (widget.loadingWidget != null) {
        return widget.loadingWidget;
      } else {
        return Container(
          color: Colors.black,
        );
      }
    } else {
      return CameraPreview(_controller!);
    }
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
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    ;
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
        "gelmedi";
  }

  predict(img) async {
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
    predictions = recognitions ?? [];
  }
}
