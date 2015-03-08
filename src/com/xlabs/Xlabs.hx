import js.Lib;
import js.Browser;

@:final
class Xlabs{
  private var config:Array<Dynamic> = null;
  private var callbackReady = null;
  private var callbackState = null;
  private var callbackIdPath = null;
  private var apiReady:Bool = false;
  private var t1:Float = 0;

  public static function main(){
    untyped window.xLabs = new Xlabs();
  }
  public function new(){ }

  public function setConfig(path:String, value):Void{
    var config = {path: path, value:value};
    var message = {target: 'xLabs', config: config};
    Browser.window.postMessage(message, '*');
  }

/*
  public function getConfig(path:String){
    return getObjectProperty(config, path);
  }
  //need to look into this shit. apparently for json extraction
  private function getObjectProperty(object:Array<Dynamic>, path:String):Dynamic{
    if(object == null || object.length == 0) return "";
    var parts:Array<String> = path.split(".");

    return object[parts.length-1];
  }*/
  

  ////////////////////////////////////////////////
  // Calibration
  ////////////////////////////////////////////////
  inline private function getTimestamp():Float{
    return Date.now().getTime();
  }
  
  public function resetCalibrationTruth():Void{
    t1 = 0;
  }

  public function updateCalibrationTruth(xScreen, yScreen):Void{
    var t1:Float = this.t1;
    var t2:Float = getTimestamp();

    if( t1 <= 0){
      t1 = t2;
      t2 ++;
    }

    addCalibrationTruth(t1, t2, xScreen, yScreen);
    this.t1 = t2;
  }

  public function addCalibrationTruth(t1:Float, t2:Float, xScreen, yScreen):Void{
    var csv = t1+","+t2+","+xScreen+","+yScreen;
    trace("truth: "+csv);
    setConfig("truth.append", csv);
  }

  public function calibrate(?id):Void{
    var request = "3p";
    if (id != null) request = id;

    setConfig("calibration.request", request);
    trace("Calibrating..");
  }

  public function calibrationClear():Void{
    setConfig("calibration.clear", null);
    trace("Clearing calibration...");
  }

  


  




}
