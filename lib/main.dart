import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:objectdetection/camera.dart';

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
      home: MyHomePage(title: 'Ali Hakanı Sert Sert TTen'),
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
  int _counter = 0;

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
                                    builder: (context) => Camera()))

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
    var wid = Center(
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), Text('Kamera Yükleniyor...')],
        ),
      ),
    );
    return wid;
  }
}
