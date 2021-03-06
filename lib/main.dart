import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera.dart';
/* import 'package:objectdetection/camera_backup.dart'; */

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Detection'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Center(child: Text(widget.title)),
        ),
        body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                  child: Text(
                'TFLITE Object Detection',
                style: TextStyle(fontSize: 30),
              )),
              Center(
                  child: TextButton(
                      onPressed: () => {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Camera(
                                          loadingWidget: loadingWidget,
                                        )))
                          },
                      child: Text(
                        'Giriş Yap',
                        style: TextStyle(fontSize: 25),
                      )))
            ],
          ),
        ));
  }

  Widget get loadingWidget {
    var wid = Center(child: CircularProgressIndicator());
    return wid;
  }
}
