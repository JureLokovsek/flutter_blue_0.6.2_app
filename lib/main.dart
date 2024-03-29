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

 // TIP: https://github.com/pauldemarco/flutter_blue/issues/404

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<BluetoothDescriptor> deviceDescriptors;
  List<BluetoothCharacteristic> deviceCharacteristics;
  List<BluetoothService> deviceServices;

  FlutterBlue _flutterBlueInstance = FlutterBlue.instance;
  BluetoothDevice bluetoothDevice;

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

    _flutterBlueInstance.startScan(timeout: Duration(seconds: 60));
    _flutterBlueInstance.scanResults.listen((scanResults) => {
      scanResults.forEach((scanResult) async {
      Fimber.d("Device ::" + scanResult.device.name +" Id: " + scanResult.device.id.toString());
      if(Utils.isDeviceNameNonin3230(scanResult.device.name.toString()) && scanResult.device.id.toString() == "00:1C:05:FF:4E:5B") {
      Fimber.d("Device found:");
      _flutterBlueInstance.stopScan();
      Future.delayed(Duration(seconds: 2)); //recommend
      bluetoothDevice = scanResult.device;
      await bluetoothDevice.connect(timeout: Duration(seconds: 120), autoConnect: false);
       deviceServices = await bluetoothDevice.discoverServices();
        initBluetoothServicesCharacteristicsAndDescriptors1(deviceServices, bluetoothDevice);

//        getSpotCheckMeasurementDataNonin3230Future(deviceServices)
//        .then((values) {
//          if(values.length > 0) {
//          Fimber.d("Measurement Values: " + values.toString());
//          }
//        })
//        .then((val) {
//          getBatteryDataNonin3230Future(deviceServices)
//          .then((values) {
//            if(values.length > 0) {
//              Fimber.d("Battery Values: " + values.toString());
//            }
//          });
//        })
//        .then((val) {
//          setupControlPointNotificationNonin3230Future(services)
//          .then((values) => {
//            if(values.length != 0) {
//                Fimber.d("Device name information Values: " + values.toString()),
//            }
//          });
//        })

       }
      })
    });

  }

  Future<List<int>> getBatteryDataNonin3230Future(List<BluetoothService> services) async {
    String _BATTERY_LEVEL_CHARACTERISTIC = "00002a19-0000-1000-8000-00805f9b34fb";
    List<int> values = List<int>();
    bool foundFirstTime = false;

    List<BluetoothCharacteristic> characteristicList = List<BluetoothCharacteristic>();
    services.forEach((service) => {
      characteristicList.addAll(service.characteristics),
    });

    for(final characteristic in characteristicList) {
      if(characteristic.uuid.toString() == _BATTERY_LEVEL_CHARACTERISTIC && foundFirstTime == false) {
        foundFirstTime = true;
        Fimber.d("Wating For Data From Characteristic : " + characteristic.uuid.toString());
        values = await characteristic.read();
      }
    }
    return values;
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

  Future<List<int>> getSpotCheckMeasurementDataNonin3230Future(List<BluetoothService> services) async {
    String _PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC = "00002a5e-0000-1000-8000-00805f9b34fb";
    List<int> values = List<int>();
    bool foundFirstTime = false;

    List<BluetoothCharacteristic> characteristicList = List<BluetoothCharacteristic>();
    services.forEach((service) => {
      characteristicList.addAll(service.characteristics),
    });

    for(final characteristic in characteristicList) {
      if(characteristic.uuid.toString() == _PLX_SPOT_CHECK_MEASUREMENT_CHARACTERISTIC && foundFirstTime == false) {
        foundFirstTime = true;
        Fimber.d("Wating For Data From Characteristic : " + characteristic.uuid.toString());
        await characteristic.setNotifyValue(true);
        characteristic.value.listen((value) {
          if(value.length > 0) {
            Fimber.d("Received data: " + value.toString());
            values.addAll(value);
          }
        });
      }
    }
    return values;
  }

//  Future<List<int>> setupControlPointNotificationNonin3230Future(List<BluetoothService> services) async {
//    String _NONIN_CONTROL_POINT_CHARACTERISTIC = "1447af80-0d60-11e2-88b6-0002a5d5c51b";
//
//    List<int> values = List<int>();
//    bool foundFirstTime = false;
//
//    List<BluetoothCharacteristic> characteristicList = List<BluetoothCharacteristic>();
//    services.forEach((service) => {
//      characteristicList.addAll(service.characteristics),
//    });
//
//    for(final characteristic in characteristicList) {
//      if(characteristic.uuid.toString() == _NONIN_CONTROL_POINT_CHARACTERISTIC && foundFirstTime == false) {
//        foundFirstTime = true;
//        Fimber.d("Wating For Data From Characteristic Point : " + characteristic.uuid.toString());
//        await characteristic.setNotifyValue(true);
//        characteristic.value.listen((value) {
//          values.addAll(value);
//        });
//      } else {
//        Fimber.d("Not found Point : " + _NONIN_CONTROL_POINT_CHARACTERISTIC);
//      }
//    }
//    return values;
//  }

//  Future<List<int>> getDeviceInformationDataNonin3230Future(List<BluetoothService> services) async {
//    String _MANUFACTURER_NAME_CHARACTERISTIC = "00002a29-0000-1000-8000-00805f9b34fb";
//    List<int> values = List<int>();
//    bool foundFirstTime = false;
//
//    List<BluetoothCharacteristic> characteristicList = List<BluetoothCharacteristic>();
//    services.forEach((service) => {
//      characteristicList.addAll(service.characteristics),
//    });
//
//    for(final characteristic in characteristicList) {
//      if(characteristic.uuid.toString() == _MANUFACTURER_NAME_CHARACTERISTIC && foundFirstTime == false) {
//        foundFirstTime = true;
//        Fimber.d("Wating For Data From Characteristic : " + characteristic.uuid.toString());
//        await characteristic.setNotifyValue(true);
//        characteristic.value.listen((value) {
//          if(value.length > 0) {
//            Fimber.d("Received data: " + value.toString());
//            values.addAll(value);
//          }
//        });
//      }
//    }
//    return values;
//  }

//  Future<List<int>> getDeviceTimeDataNonin3230Future(List<BluetoothService> services) async {
//    String _CURRENT_TIME_CHARACTERISTIC = "00002A2B-0000-1000-8000-00805f9b34fb";
//    String _DATE_TIME_CHARACTERISTIC = "00002A08-0000-1000-8000-00805f9b34fb";
//    List<int> values = List<int>();
//    bool foundFirstTime = false;
//
//    List<BluetoothCharacteristic> characteristicList = List<BluetoothCharacteristic>();
//    services.forEach((service) => {
//      characteristicList.addAll(service.characteristics),
//    });
//
//    for(final characteristic in characteristicList) {
//      if(characteristic.uuid.toString() == _MANUFACTURER_NAME_CHARACTERISTIC && foundFirstTime == false) {
//        foundFirstTime = true;
//        Fimber.d("Wating For Data From Characteristic : " + characteristic.uuid.toString());
//        await characteristic.setNotifyValue(true);
//        characteristic.value.listen((value) {
//          if(value.length > 0) {
//            Fimber.d("Received data: " + value.toString());
//            values.addAll(value);
//          }
//        });
//      }
//    }
//    return values;
//  }

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
    if(bluetoothDevice != null) {
      Fimber.d("Disconnecting from Device: " + bluetoothDevice.name.toString());
      bluetoothDevice.disconnect();
    }
  }

  initBluetoothServicesCharacteristicsAndDescriptors(List<BluetoothService> services, BluetoothDevice device) {
    Fimber.d("Discovered Service, Characteristics and Included Services for Device: " + device.name.toUpperCase() +" Address: " + device.id.toString());
     deviceDescriptors = List<BluetoothDescriptor>();
     deviceCharacteristics = List<BluetoothCharacteristic>();
     deviceServices = List<BluetoothService>();

    services.forEach((service){
      Fimber.d("Discovered Service: " + service.uuid.toString());
      Fimber.d("\n");
      deviceServices.add(service);
      service.characteristics.forEach((characteristics) {
        Fimber.d("Discovered Characteristics: " + characteristics.uuid.toString());
        deviceCharacteristics.add(characteristics);
        characteristics.descriptors.forEach((descriptor) {
          Fimber.d("Discovered Descriptor: " + descriptor.uuid.toString());
          deviceDescriptors.add(descriptor);
        });
      });
      Fimber.d("\n \n");
      service.includedServices.forEach((includedService){
        Fimber.d("Discovered Included Service: " + includedService.uuid.toString());
      });
      Fimber.d("\n \n");
    });
    Fimber.d("\n \n");
  }

  initBluetoothServicesCharacteristicsAndDescriptors1(List<BluetoothService> services, BluetoothDevice device) {
    Fimber.d("Discovered Service, Characteristics and Included Services for Device: " + device.name.toUpperCase() +" Address: " + device.id.toString());
//    deviceDescriptors = List<BluetoothDescriptor>();
//    deviceCharacteristics = List<BluetoothCharacteristic>();
//    deviceServices = List<BluetoothService>();
//
//    services.forEach((service){
//      service.includedServices.forEach((includedService){
//        Fimber.d("Discovered Service: " + includedService.uuid.toString());
//      });
//      Fimber.d("\n \n");
//    });
  }

}
