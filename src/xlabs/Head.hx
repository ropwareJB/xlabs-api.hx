package xlabs;

@author('Josh.epidev')
class Head{

  public var pos(default, null):Point3;
  public var roll(default, null):Float;
  public var pitch(default, null):Float;
  public var yaw(default, null):Float;

  public function new(obj){
    pos = new Point3(cast(obj.x, Float), 
                     cast(obj.y, Float),
                     cast(obj.z, Float));
    roll = cast(obj.roll, Float);
    pitch = cast(obj.pitch, Float);
    yaw = cast(obj.yaw, Float);
  }

}
