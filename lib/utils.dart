class Utils {

  static bool isDeviceNameNonin3230(String deviceName) {
    RegExp exp = new RegExp("(Nonin3230)+");
    return exp.hasMatch(deviceName);
  }

  static bool isDeviceNameMiBand3(String deviceName) {
    RegExp exp = new RegExp("(Mi Band 3)");
    return exp.hasMatch(deviceName);
  }

  static bool isDeviceNameMiSmartBand4(String deviceName) {
    RegExp exp = new RegExp("(Mi Smart Band 4)");
    return exp.hasMatch(deviceName);
  }


}