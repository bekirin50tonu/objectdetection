import 'dart:ffi';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite/tflite.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Camera extends StatefulWidget {
  final loadingWidget;

  const Camera({Key? key, @required this.loadingWidget}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> with WidgetsBindingObserver {
  double _imageHeight = 0.0;
  double _imageWidth = 0.0;
  bool isProgress = false;
  Size? containerSize;

  String res = "unsuccess";

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCamera = 0;

  List<Widget> boxes = [];

  @override
  void initState() {
    super.initState();
    setupTfLite();
    setupCamera();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    _controller?.dispose();
    WidgetsBinding.instance!.addObserver(this);
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
      setupCamera();
      setupTfLite();
    }
  }

  @override
  Widget build(BuildContext context) {
    _imageHeight = MediaQuery.of(context).size.height;
    _imageWidth = MediaQuery.of(context).size.width;
    containerSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Camera')),
      ),
      body: Container(
          child: _controller == null && res == "unsuccess"
              ? widget.loadingWidget
              : Stack(
                  children: [
                    Text(
                      res,
                      style: TextStyle(fontSize: 50, color: Colors.white),
                    ),
                    SizedBox(
                        height: _imageHeight,
                        width: _imageWidth,
                        child: CameraPreview(_controller!)),
                    Stack(
                      children: boxes,
                    )
                  ],
                )),
    );
  }

  void setupTfLite() async {
    res = await Tflite.loadModel(
            model: "assets/tflite.tflite",
            labels: "assets/labels.txt",
            numThreads: 1,
            isAsset: true,
            useGpuDelegate: false) ??
        "unsuccess";
    print(res.toUpperCase());
  }

  List<Widget> renderBoxes(List<dynamic>? predictions, int height, int width) {
    if (containerSize == null) return [];
    Size screen = containerSize ?? Size(31, 31);

    double factorX = screen.width;
    double factorY = _imageHeight / _imageHeight * screen.width;

    Color blue = Colors.blue;
    return predictions!.map((re) {
      return Container(
        child: Positioned(
            left: re["rect"]["x"] * factorX,
            top: re["rect"]["y"] * factorY,
            width: re["rect"]["w"] * factorX,
            height: re["rect"]["h"] * factorY,
            child: ((re["confidenceInClass"] > 0.50))
                ? Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: blue,
                      width: 3,
                    )),
                    child: Text(
                      "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        background: Paint()..color = blue,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  )
                : Container()),
      );
    }).toList();
  }

  void setupCamera() async {
    await [Permission.camera].request();
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.low);
    _controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});

      _controller!.startImageStream((CameraImage img) {
        if (!isProgress) {
          isProgress = true;
          Tflite.detectObjectOnFrame(
            bytesList: img.planes.map((plane) {
              return plane.bytes;
            }).toList(),
            model: "ResNet",
            imageHeight: img.height,
            imageWidth: img.width,
            imageMean: 127.5,
            imageStd: 127.5,
            numResultsPerClass: 3,
            threshold: 0.8,
          ).then((recognitions) {
            print(recognitions);
            setState(() {
              boxes = renderBoxes(recognitions, img.height, img.width);
            });
            isProgress = false;
          }).catchError((onError) => {print(onError)});
        }
      });
    });
  }
}
