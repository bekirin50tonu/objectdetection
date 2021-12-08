import 'dart:typed_data';

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
  List<dynamic>? predictions = [];
  String? output = "";
  double confidence = 0.0;
  CameraImage? img;
  bool isProgress = false;

  @override
  void initState() {
    super.initState();
    setupCameras();
    setupTfLite();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() async {
    _controller!.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    Tflite.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
      await Tflite.close();
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
          child: Column(children: [
        _controller == null
            ? widget.loadingWidget
            : CameraPreview(_controller!),
        Text(predictions!.length.toString()),
        Text(confidence.toString()),
        Text(output ?? "Bulunamadı"),
      ])),
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
    _controller = await selectCamera();
    _controller!.initialize().then((value) => {process()});
  }

  Future<void> process() async {
    if (!mounted) {
      return;
    } else {
      _controller!.startImageStream((image) => {img = image, recognitions()});
    }
  }

  selectCamera() async {
    var controller =
        CameraController(_cameras[_selected], ResolutionPreset.medium);
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
            numThreads: 2,
            isAsset: true,
            useGpuDelegate: false) ??
        "unsuccess";
  }

  Future<void> recognitions() async {
    if (img == null) return;
    if (isProgress) return;
    isProgress = true;
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: img!.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: img!.height,
        imageWidth: img!.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 1, // defaults to 5
        threshold: 0.5, // defaults to 0.1
        asynch: true // defaults to true
        );
    isProgress = false;

    var xd = recognitions!.map((e) => print(e['rect']));
    if (recognitions == null) return;
    recognitions.forEach((element) => {
          setState(() => {
                output = element['label'],
                confidence = element['confidence'],
                print(element)
              })
        });
  }
}
