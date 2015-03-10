package;

import xlabs.*;

class Main{
  public static function main(){
    var xlabs = new Xlabs();
    var testcases = CompileTime.getAllClasses("xlabs"); 
    trace("num: " +testcases.length);
    for ( testClass in testcases ) trace(testClass);
  }
}
