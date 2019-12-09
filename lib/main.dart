import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:async/async.dart';
import 'package:rxdart/rxdart.dart';

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

  var _scannedDevice;

//  String _miBand3Address = "E3:22:C4:77:73:E8";
  String _noninAddress = "00:1C:05:FF:4E:5B";
 // String _BATTERY_LEVEL_CHARACTERISTIC = "00002a19-0000-1000-8000-00805f9b34fb";
 // String _BATTERY_LEVEL_SERVICE = "0000180f-0000-1000-8000-00805f9b34fb";
  String _PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC = "00002a5e-0000-1000-8000-00805f9b34fb";
  //String _PLX_SPOT_CHECK_MEASUREMENT_SERVICE = "00001822-0000-1000-8000-00805f9b34fb";

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
            RaisedButton(
              padding: EdgeInsets.only(left: 50.0, right: 50.0),
              color: Theme.of(context).primaryColorDark,
              textColor: Theme.of(context).primaryColorLight,
              child: Text("Scan and get Data", textScaleFactor: 1.5),
              onPressed: _scanAndGetData,
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
    flutterBlue.setLogLevel(LogLevel.debug);

    // TODO: info stuff ... https://pub.dev/packages/flutter_blue#-readme-tab

    flutterBlue.isOn.asStream()
        .take(1)
        .listen((status) => {
      Fimber.d("Is On: " + status.toString()),
    });

    flutterBlue.isAvailable.asStream()
        .take(1)
        .listen((status) => {
      Fimber.d("Is Available: " + status.toString()),
    });

    flutterBlue.isScanning
        .take(1)
        .listen((status) => {
      Fimber.d("Is isScanning: " + status.toString()),
    });

    flutterBlue.startScan(timeout: Duration(seconds: 60));
    flutterBlue.scanResults.listen((scanResults) async {
      // do something with scan result
      for (var scanResult in scanResults) {
        Fimber.d("Device ::" + scanResult.device.name +" Id: " + scanResult.device.id.toString());
        if(scanResult.device.id.toString() == _noninAddress) {
          Fimber.d("Device found:");
          flutterBlue.stopScan();
          var device = scanResult.device;
          await device.connect(timeout: Duration(seconds: 20), autoConnect: false);
          List<BluetoothService> services = await device.discoverServices();
          services.forEach((service) {
            // do something with service
            Fimber.d("\n \n");
            Fimber.d("Service: " + service.uuid.toString());
            service.characteristics.forEach((characteristics){
              Fimber.d("Characteristics: " + characteristics.uuid.toString() + " Property Type: " + (characteristics.isNotifying == true ? "is Notify Property" : "is Indicate Property"));
              characteristics.descriptors.forEach((descriptors){
                Fimber.d("Descriptors: " + descriptors.uuid.toString());
              });
            });
            Fimber.d("\n \n");
          });
          device.disconnect();
        }
      }
    });


  }

  void _scanAndGetData() {
    List<BluetoothDescriptor> descriptors;
    List<BluetoothCharacteristic> characteristics;
    List<BluetoothService> services;
    List<int> value;
    bool foundFirstTime = false;

    flutterBlue.startScan(timeout: Duration(seconds: 60));
    flutterBlue.scanResults.listen((scanResults) => {
      scanResults.forEach((scanResult) async => {
      Fimber.d("Device ::" + scanResult.device.name +" Id: " + scanResult.device.id.toString()),
      if(scanResult.device.id.toString() == _noninAddress) {
      Fimber.d("Device found:"),
      flutterBlue.stopScan(),
      _scannedDevice = scanResult.device,
      await _scannedDevice.connect(timeout: Duration(seconds: 120), autoConnect: false),
         services = await _scannedDevice.discoverServices(),

        services.forEach((service) => {
          characteristics = service.characteristics.toSet().toList(),

          characteristics.forEach((char) async =>{
           // Fimber.d("Char: " + char.uuid.toString()),
              if(char.uuid.toString() == "00002a5e-0000-1000-8000-00805f9b34fb" && foundFirstTime == false) {
                Fimber.d("Ok: " + char.uuid.toString()),
                foundFirstTime = true,

                await char.setNotifyValue(true),
                    char.value.listen((value) {
                  // do something with new value
                      Fimber.d("Byte: " + value.toString());
                }),

              }
          }),


        }),
       // _scannedDevice.disconnect(),

      }
      })
    });

  }

  void _floatingBarAction() {
    Fimber.d("Floating bar");
  }

  void _stopScan() {
    if(flutterBlue != null) {
      flutterBlue.stopScan();
    }
    if(_scannedDevice != null) {
      _scannedDevice.disconnect();
    }
  }

}
