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

  /*
   * Constructor
   *    Create a new instance of the API interface object, and attach listeners
   *    for when the API has entered its ready state, when the dataset is updated,
   *    and when the IdPath is set.
   */
  public function new(){
    var doc = Browser.document;
    doc.addEventListener("xLabsApiReady", onApiReady);
    doc.addEventListener("xLabsApiState", function(event){onApiState(event.detail);});
    doc.addEventListener("xLabsApiIdPath", function(event){onApiIdPath(event.detail);});
  }

  /*
   * setConfig
   *    Send a query to the xlabs plugin for some data or to perform some function
   */
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

  /*
   * updateCalibrationTruth
   *    Add a data point to the calibration to decrease the uncertaintly
   *    factor and hence increase accuracy
   */
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

  /*
   * addCalibrationTruth
   *    Add a data point during the calibration procedure, recording
   *    the looked-at point and the screen point.
   */
  public function addCalibrationTruth(t1:Float, t2:Float, xScreen, yScreen):Void{
    var csv = t1+","+t2+","+xScreen+","+yScreen;
#if debug
    trace("truth: "+csv);
#end
    setConfig("truth.append", csv);
  }

  /*
   * calibrate 
   *    Request initiation of the calibration procedure on the xlabs
   *    browser plugin. Used in conjunction with the calibrationClear method
   */
  public function calibrate(?id="3p"):Void{
    setConfig("calibration.request", id);
#if debug
    trace("Calibrating..");
#end
  }

  /*
   * calibrationClear
   *    Clear the calibration, to force recalibration at a later time
   */
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
  inline private function calcDpi(?w:Float=1, ?h:Float=1, ?d:Float=13.3, ?opt:String='d'):Float{
    var dpi = (opt == 'd' ? Math.sqrt(w*w + h*h) : opt == 'w' ? w : h) / d;
    return dpi>0 ? Math.round(dpi) : 0;
  }

  //////////////////////////////////////////////
  // Coordinate conversion
  //////////////////////////////////////////////

  /*
   *  documentOffset
   *    Get the offset of the document as a Point object.
   *    Probably better described as the scroll
   */
  public function documentOffset():Point{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var x = cast(getConfig("browser.document.offset.x"), Float);
    var y = cast(getConfig("browser.document.offset.y"), Float);
    return {x:x, y:y};
  }

  /*
   * documentOffsetReady
   *    Check if the document offset data is readily-available
   */
  public function documentOffsetReady():Bool{
    return getConfig("browser.document.offset.ready") == "1";
  }

  /*
   * Screen x-Point to Document x-Point
   *    Convert a point from the screen's reference to the
   *    a point from the document's point of reference.     
   */
  private function scr2docX(screenX:Float):Float{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var xOffset = cast(getConfig("browser.document.offset.x"), Float);
    return screenX - Browser.window.screenX - xOffset;
  }

  /*
   * Screen y-Point to Document y-Point
   *    Convert a point from the screen's reference to the
   *    a point from the document's point of reference.
   * */
  private function scr2docY(screenY:Float):Float{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var yOffset = cast(getConfig("browser.document.offset.y"), Float);
    return screenY - Browser.window.screenY - yOffset;
  }

  /*
   * Screen Point to Document Point
   *    Convert a point from the screen's reference to the
   *    a point from the document's point of reference.
   * */
  public function scr2doc(screenX:Float, screenY:Float):Point{
    return {
      x: scr2docX(screenX),
      y: scr2docY(screenY)
    };
  }

  /*
   * Document x-Point to screen x-Point
   *    Convert a point from the document's reference to the
   *    a point from the screen's point of reference.
   * */
  private function doc2scrX(docX:Float):Float{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var xOffset = cast(getConfig("browser.document.offset.x"), Float);
    return docX + Browser.window.screenX + xOffset;
  }

  /*
   * Document y-Point to screen y-Point
   *    Convert a point from the document's reference to the
   *    a point from the screen's point of reference.
   * */
  private function doc2scrY(docY:Float):Float{
    if(!documentOffsetReady()) throw new Error(DOC_OFFSET_ERROR_MSG);

    var yOffset = cast(getConfig("browser.document.offset.y"), Float);
    return docY + Browser.window.screenY + yOffset;
  }

  /*
   * Document Point to screen Point
   *    Convert a point from the document's reference to the
   *    a point from the screen's point of reference.
   * */
  public function doc2scr(docX:Float, docY:Float):Point{
    return {
      x: doc2scrX(docX),
      y: doc2scrY(docY)
    };
  }


  /////////////////////////////////////////////////////
  // Setup
  /////////////////////////////////////////////////////
  /*
   *  onApiReady
   *    Listener for the xlabs ApiReady event,
   *    notifies its listener when the event occurs.
   */
  private function onApiReady():Void{
    apiReady = true;
    if(callbackReady != null) callbackReady();
  }

  /*
   * onApiState 
   *    Listener for the xlabs onApiState event,
   *    notifies its listener when the event occurs,
   *    and updates the reported data set.
   */
  private function onApiState(config):Void{
    this.config = config;
    if(callbackState != null) callbackState();
  }

  /*
   * onApiIdPath 
   *    Listener for the xlabs onApiIdPath event,
   *    notifies its listener when the event occurs.
   */
  private function onApiIdPath(detail):Void{
    if(callbackIdPath != null) callbackIdPath(detail.id, detail.path);
  }

  /*
   *  setup 
   *    Listener for the xlabs ApiReady event,
   *    notifies its listener when the event occurs.
   */
  public function setup(?callbackReady:Void->Void, ?callbackState:Void->Void, ?callbackIdPath:String->String->Void){
    this.callbackReady = callbackReady;
    this.callbackState = callbackState;
    this.callbackIdPath = callbackIdPath;
    if(apiReady) callbackReady();
  }

}
