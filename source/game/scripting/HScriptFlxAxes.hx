package game.scripting;

import flixel.util.FlxAxes;

class HScriptFlxAxes {
    public static inline var X:Int = cast FlxAxes.X;
    public static inline var Y:Int = cast FlxAxes.Y;
    public static inline var XY:Int = cast FlxAxes.XY;
    public static inline var NONE:Int = cast FlxAxes.NONE;
    
    public static function fromString(str:String):Null<Int> {
        return switch (str.toLowerCase().trim()) {
            case "x": X;
            case "y": Y;
            case "xy" | "both": XY;
            case "none": NONE;
            default: null;
        }
    }
    
    public static function toString(axes:Int):String {
        return switch (axes) {
            case X: "X";
            case Y: "Y";
            case XY: "XY";
            case NONE: "NONE";
            default: "UNKNOWN";
        }
    }
}