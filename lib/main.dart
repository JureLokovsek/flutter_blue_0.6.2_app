import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:async/async.dart';
import 'package:rxdart/rxdart.dart';

import 'utils.dart';

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

  FlutterBlue _flutterBlueInstance = FlutterBlue.instance;
  BluetoothDevice _bluetoothDevice;

  String _BATTERY_LEVEL_CHARACTERISTIC = "00002a19-0000-1000-8000-00805f9b34fb";
  String _PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC = "00002a5e-0000-1000-8000-00805f9b34fb";

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
              onPressed: _startScanForDeviceProperties,
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
              child: Text("Disconnect", textScaleFactor: 1.5),
              onPressed: _disconnect,
            ),
            RaisedButton(
              padding: EdgeInsets.only(left: 50.0, right: 50.0),
              color: Theme.of(context).primaryColorDark,
              textColor: Theme.of(context).primaryColorLight,
              child: Text("Scan For Nonin and get Byte Data", textScaleFactor: 1.5),
              onPressed: _scanForNoninAndGetByteData,
            ),
            RaisedButton(
              padding: EdgeInsets.only(left: 50.0, right: 50.0),
              color: Theme.of(context).primaryColorDark,
              textColor: Theme.of(context).primaryColorLight,
              child: Text("Just Testing", textScaleFactor: 1.5),
              onPressed: _justTesting,
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

  void _startScanForDeviceProperties() {
    Fimber.d("Test Ble Clicked");
    _flutterBlueInstance.setLogLevel(LogLevel.debug);

    // TODO: info stuff ... https://pub.dev/packages/flutter_blue#-readme-tab

    _flutterBlueInstance.isOn.asStream()
        .take(1)
        .listen((status) => {
      Fimber.d("Is On: " + status.toString()),
    });

    _flutterBlueInstance.isAvailable.asStream()
        .take(1)
        .listen((status) => {
      Fimber.d("Is Available: " + status.toString()),
    });

    _flutterBlueInstance.isScanning
        .take(1)
        .listen((status) => {
      Fimber.d("Is isScanning: " + status.toString()),
    });

    _flutterBlueInstance.startScan(timeout: Duration(seconds: 60));
    _flutterBlueInstance.scanResults.listen((scanResults) async {
      // do something with scan result
      for (var scanResult in scanResults) {
        Fimber.d("Device ::" + scanResult.device.name +" Id: " + scanResult.device.id.toString());
        if(Utils.isDeviceNameNonin3230(scanResult.device.name.toString())) { // TODO: scanning for Nonin 3230.
          Fimber.d("Device found:");
          _flutterBlueInstance.stopScan();
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

  void _scanForNoninAndGetByteData() {
    List<BluetoothDescriptor> descriptors;
    List<BluetoothCharacteristic> characteristics;
    List<BluetoothService> services;
    List<int> value;
    bool foundFirstTime = false;
    Future<List<int>> list;

    _flutterBlueInstance.startScan(timeout: Duration(seconds: 60));
    Future<List<BluetoothService>> ok;
    Stream<bool> oh;
    _flutterBlueInstance.scanResults.listen((scanResults) => {
      scanResults.forEach((scanResult) async => {
      Fimber.d("Device ::" + scanResult.device.name +" Id: " + scanResult.device.id.toString()),
      if(Utils.isDeviceNameNonin3230(scanResult.device.name.toString())) {
      Fimber.d("Device found:"),
      _flutterBlueInstance.stopScan(),
      _bluetoothDevice = scanResult.device,
      await _bluetoothDevice.connect(timeout: Duration(seconds: 120), autoConnect: false),
       services = await _bluetoothDevice.discoverServices(),
//        oh = _bluetoothDevice.isDiscoveringServices,
//        oh.take(1)
//        .distinct()
//        .listen((status)=> {
//        if(status) {
//                Fimber.d("Discovering Services: " + status.toString()),
//              } else {
//                Fimber.d("Discovering Services: " + status.toString()),
//              }
//        }).onDone(()=> getBatteryLevelNonin3230(services, _BATTERY_LEVEL_CHARACTERISTIC)),

        getBatteryLevelNonin3230(services, _BATTERY_LEVEL_CHARACTERISTIC)
        .then((val) => {
          Fimber.d("Val: " + val.toString()),
        }),
       //  services.forEach((service) => {
        //  characteristics = service.characteristics.toSet().toList(),

//          characteristics.forEach((characteristic) =>{
//              // Fimber.d("Char: " + characteristic.uuid.toString()),
//              if(characteristic.uuid.toString() == _BATTERY_LEVEL_CHARACTERISTIC && foundFirstTime == false) {
//                Fimber.d("Characteristic found: " + characteristic.uuid.toString()),
//                foundFirstTime = true,
//              //  getDataFromNotifyCharacteristic(characteristic),
//                list = characteristic.read(),
//                list.then((value)=> {
//                  Fimber.d("Battery Values: " + value.toString()),
//                }),
//              }
//          }),

       // }),

       // _scannedDevice.disconnect(),

      }
      })
    });

  }

  Future<List<int>> getBatteryLevelNonin3230(List<BluetoothService> services, String batteryCharacteristic) async {
    bool foundFirstTime = false;
   // int batteryLevel;
    List<int> batteryLevelValues;
    //List<BluetoothCharacteristic> listWithDuplicatedCharacteristics = List<BluetoothCharacteristic>();
    List<BluetoothCharacteristic> characteristicList = List<BluetoothCharacteristic>();
    services.forEach((service) => {
      characteristicList.addAll(service.characteristics),
    });

//    BluetoothCharacteristic batteryChar = characteristicList.firstWhere((characteristic)=> characteristic.uuid.toString() == _BATTERY_LEVEL_CHARACTERISTIC);
//    Observable.just(batteryChar)
//    .distinct()
//    .take(1)
//    .listen((char) => {
//      Fimber.d("Char: " + char.uuid.toString()),
//    });


    for(final char in characteristicList){
      Fimber.d("Char: " + char.uuid.toString()); // 00002a19-0000-1000-8000-00805f9b34fb
      if(char.uuid.toString() == _BATTERY_LEVEL_CHARACTERISTIC && foundFirstTime == false) {
        foundFirstTime = true;
        Fimber.d("Char is present: Start reading: " + char.uuid.toString());
        batteryLevelValues = await char.read();
        _bluetoothDevice.disconnect();
        break;
      }
      return batteryLevelValues;
    }
    return batteryLevelValues;

//    services.forEach((service) => {
//      service.characteristics.toSet().toList().forEach((characteristic) async => {
//        // Fimber.d("Char: " + characteristic.uuid.toString()),
//        if(characteristic.uuid.toString() == batteryCharacteristic && foundFirstTime == false) {
//          Fimber.d("Characteristic found: " + characteristic.uuid.toString()),
//          foundFirstTime = true,
//          batteryLevelValues = await characteristic.read(),
//          batteryLevel = batteryLevelValues.elementAt(0).toInt(),
//        } else {
//          Fimber.d("Characteristic not found in the provided service list: " + batteryCharacteristic),
//        }
//      }),
//    });
  }

  void _justTesting() {
    List<BluetoothDevice> list = scanForDevices(5);
  }

  List<BluetoothDevice> scanForDevices(int scanDurationInSeconds) {
    Fimber.d("Scan Started");
    List<BluetoothDevice> bluetoothDevicesList = List<BluetoothDevice>();
    _flutterBlueInstance.startScan(timeout: Duration(seconds: scanDurationInSeconds));
    _flutterBlueInstance.scanResults.listen((scanResults) => {
      scanResults.forEach((scanResult) => {
        Fimber.d("Discovered Device ::" + scanResult.device.name +" Id: " + scanResult.device.id.toString()),
        bluetoothDevicesList.add(scanResult.device),
      })
    });
    return bluetoothDevicesList;
  }

  Future<List<int>> getDataFromNotifyCharacteristic(BluetoothCharacteristic characteristic) async {
    Fimber.d("Wating for Data From Notify Characteristic : " + characteristic.uuid.toString());
    List<int> dataValue = List<int>();
    await characteristic.setNotifyValue(true);
    characteristic
        .value
        .listen((value) {
        if(value.length > 0) {
            Fimber.d("Received data: " + value.toString());
            dataValue.addAll(value);
          }
        });
    return dataValue;
  }

  void _floatingBarAction() {
    Fimber.d("Floating bar");
  }

  void _stopScan() {
    if(_flutterBlueInstance != null) {
      _flutterBlueInstance.isScanning
          .take(1)
          .listen((status) => {
        Fimber.d("Is isScanning: " + status.toString()),
        if(status) {
          _flutterBlueInstance.stopScan(),
          Fimber.d("Scanning stoped:"),
        }
      });
    }
  }

  void _disconnect() {
    if(_bluetoothDevice != null) {
      Fimber.d("Disconnecting from Device: " + _bluetoothDevice.name.toString());
      _bluetoothDevice.disconnect();
    }
  }

}
