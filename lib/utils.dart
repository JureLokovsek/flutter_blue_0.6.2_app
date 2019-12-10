class Utils {

  static bool isDeviceNameNonin3230(String deviceName) {
    RegExp exp = new RegExp("(Nonin3230)+");
    return exp.hasMatch(deviceName);
  }


}