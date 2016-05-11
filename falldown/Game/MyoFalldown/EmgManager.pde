interface IEmgManager {
  void calibrate();
  HashMap<String, Float> poll();
  void onEmg(long nowMillis, int[] sensorData);
}


class EmgManager implements IEmgManager {
  Myo myo;
  MyoAPI myoAPI;
  String SETTINGS_EMG_CONTROL_POLICY;
  boolean calibrated;

  EmgManager(MyoFalldown mainApp) {
    myo = new Myo(mainApp);
    myo.withEmg();
    myoAPI = new MyoAPI();
    SETTINGS_EMG_CONTROL_POLICY = "DIFF";
    calibrated = false;
  }

  void calibrate() {
    println("Left:");
    myoAPI.registerAction("LEFT", 5000);
    println("Right:");
    myoAPI.registerAction("RIGHT", 5000);
    calibrated = true;
  }

  HashMap<String, Float> poll() {
    assert(calibrated);

    HashMap<String, Float> readings = myoAPI.poll();
    Float left = readings.get("LEFT");
    Float right = readings.get("RIGHT");
    Float jump = (readings.get("LEFT") > 0.8 && readings.get("RIGHT") > 0.8) ?  1.0 : 0.0;

    HashMap<String, Float> toReturn = new HashMap<String, Float>();
    toReturn.put("JUMP", jump);
    switch (SETTINGS_EMG_CONTROL_POLICY) {
      case "DIFF":
        if (left > right) {
          toReturn.put("LEFT", left-right);
          toReturn.put("RIGHT", 0.0);
        } else {
          toReturn.put("RIGHT", right-left);
          toReturn.put("LEFT", 0.0);
        } 
        break;

      case "MAX":
        if (left > right) {
          toReturn.put("LEFT", left);
          toReturn.put("RIGHT", 0.0);
        } else {
          toReturn.put("RIGHT", right);
          toReturn.put("LEFT", 0.0);
        }
        break;
    }
    return toReturn;
  }

  void onEmg(long nowMillis, int[] sensorData) {
    myoAPI.onEmg(nowMillis, sensorData);
  }
}
