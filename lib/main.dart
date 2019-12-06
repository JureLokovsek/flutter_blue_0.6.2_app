import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  Fimber.plantTree(DebugTree());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Blue Ver: 0.6.2 Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            RaisedButton(
                padding: EdgeInsets.only(left: 50.0, right: 50.0),
                color: Theme.of(context).primaryColorDark,
                textColor: Theme.of(context).primaryColorLight,
                child: Text("Start Scan", textScaleFactor: 1.5),
                onPressed: _startScan,
            ),
            RaisedButton(
              padding: EdgeInsets.only(left: 50.0, right: 50.0),
              color: Theme.of(context).primaryColorDark,
              textColor: Theme.of(context).primaryColorLight,
              child: Text("Stop Scan", textScaleFactor: 1.5),
              onPressed: _stopScan,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _floatingBarAction,
        tooltip: 'Nothing for now!',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _startScan() {
    Fimber.d("Test Ble Clicked");

    // TODO: info stuff ... https://pub.dev/packages/flutter_blue#-readme-tab

    flutterBlue.startScan(timeout: Duration(seconds: 10));
    flutterBlue.scanResults.listen((scanResults) {
      // do something with scan result
      for (var scanResult in scanResults) {
        Fimber.d("Device ::" + scanResult.device.name +" Id: " + scanResult.device.id.toString());
      }
    });

  }

  void _floatingBarAction() {
    Fimber.d("Floating bar");
  }

  void _stopScan() {
    if(flutterBlue != null) {
        flutterBlue.stopScan();
    }
  }

}
