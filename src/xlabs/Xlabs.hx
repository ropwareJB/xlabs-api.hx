package xlabs;

import js.Browser;
import js.html.Screen;
import js.Error;

typedef Point = {var x:Float; var y:Float;};

@author('Josh.epidev')
@:final
class Xlabs{

  private var config:Array<Dynamic> = null;
  private var callbackReady:Void->Void = null;
  private var callbackState:Void->Void = null;
  private var callbackIdPath:String->String->Void = null;
  private var apiReady:Bool = false;
  private var t1:Float = 0;

  inline static var DPI_MATCH_MEDIA = "(min-resolution: 2dppx), (-webkit-min-device-pixel-ratio: 1.5),(-moz-min-device-pixel-ratio: 1.5),(min-device-pixel-ratio: 1.5)";
  inline static var DOC_OFFSET_ERROR_MSG = "Should not call scr2doc() unless mouse moved, i.e. browser.document.offset.ready == 1";


  public function getHead():Head return new Head(untyped config.state.head);

  public static function main(){
    untyped window.xLabs = new Xlabs();
  }

  public function new(){
    var doc = Browser.document;
    doc.addEventListener("xLabsApiReady", onApiReady);
    doc.addEventListener("xLabsApiState", function(event){onApiState(event.detail);});
    doc.addEventListener("xLabsApiIdPath", function(event){onApiIdPath(event.detail);});
  }

  public function setConfig(path:String, value):Void{
    var config = {path: path, value:value};
    var message = {target: 'xLabs', config: config};
    Browser.window.postMessage(message, '*');
  }

  /* real nasty retrieval - don't use*/
  @:deprecated
  public function getConfig(path:String){
    return getObjectProperty(config, path);
  }
  @:deprecated
  private function getObjectProperty(object:Null<Dynamic>, path:String){
    if(object == null || object.length == 0) return "";
    var parts:Array<String> = path.split(".");
    untyped for(x in parts) object = object[x];
    return object;
  }
  

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
#if debug
    trace("truth: "+csv);
#end
    setConfig("truth.append", csv);
  }

  public function calibrate(?id="3p"):Void{
    setConfig("calibration.request", id);
#if debug
    trace("Calibrating..");
#end
  }

  public function calibrationClear():Void{
    setConfig("calibration.clear", null);
#if debug
    trace("Clearing calibration...");
#end
  }

  //////////////////////////////////
  //// Resolution
  //////////////////////////////////

  public function getDpi():Float{
    var dppx:Float = Browser.window.devicePixelRatio;
    if(dppx == null || dppx == null) {
      if(Browser.window.matchMedia != null && Browser.window.matchMedia(DPI_MATCH_MEDIA).matches) dppx = 2;
      else dppx = 1;
    }
    var screen = Browser.window.screen;
    var w = screen.width * dppx;
    var h = screen.height * dppx;
    return calcDpi(w, h, 13.3, 'd');
  }

  /* Calculate PPI/DPI
   * Source: http://dpi.lv/ */
  private function calcDpi(?w:Float=1, ?h:Float=1, ?d:Float=13.3, ?opt:String='d'):Float{
    var dpi = (opt == 'd' ? Math.sqrt(w*w + h*h) : opt == 'w' ? w : h) / d;
    return dpi>0 ? Math.round(dpi) : 0;
  }

  //////////////////////////////////////////////
  // Coordinate conversion
  //////////////////////////////////////////////

  public function documentOffset():Point{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var x = cast(getConfig("browser.document.offset.x"), Float);
    var y = cast(getConfig("browser.document.offset.y"), Float);
    return {x:x, y:y};
  }

  public function documentOffsetReady():Bool{
    return getConfig("browser.document.offset.ready") == "1";
  }

  private function scr2docX(screenX:Float):Float{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var xOffset = cast(getConfig("browser.document.offset.x"), Float);
    return screenX - Browser.window.screenX - xOffset;
  }

  private function scr2docY(screenY:Float):Float{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var yOffset = cast(getConfig("browser.document.offset.y"), Float);
    return screenY - Browser.window.screenY - yOffset;
  }

  public function scr2doc(screenX:Float, screenY:Float):Point{
    return {
      x: scr2docX(screenX),
      y: scr2docY(screenY)
    };
  }

  private function doc2scrX(docX:Float):Float{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var xOffset = cast(getConfig("browser.document.offset.x"), Float);
    return docX + Browser.window.screenX + xOffset;
  }

  private function doc2scrY(docY:Float):Float{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var yOffset = cast(getConfig("browser.document.offset.y"), Float);
    return docY + Browser.window.screenY + yOffset;
  }

  public function doc2scr(docX:Float, docY:Float):Point{
    return {
      x: doc2scrX(docX),
      y: doc2scrY(docY)
    };
  }


  /////////////////////////////////////////////////////
  // Setup
  /////////////////////////////////////////////////////

  public function onApiReady():Void{
    apiReady = true;
    if(callbackReady != null) callbackReady();
  }

  public function onApiState(config):Void{
    this.config = config;
    if(callbackState != null) callbackState();
  }

  public function onApiIdPath(detail):Void{
    if(callbackIdPath != null) callbackIdPath(detail.id, detail.path);
  }

  public function setup(?callbackReady:Void->Void, ?callbackState:Void->Void, ?callbackIdPath:String->String->Void){
    this.callbackReady = callbackReady;
    this.callbackState = callbackState;
    this.callbackIdPath = callbackIdPath;
    if(apiReady) callbackReady();
  }

}
