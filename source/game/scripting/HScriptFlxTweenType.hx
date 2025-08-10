package game.scripting;

class HScriptFlxTweenType {
    public static inline var PERSIST:Int = 1;
    public static inline var LOOPING:Int = 2;
    public static inline var PINGPONG:Int = 4;
    public static inline var ONESHOT:Int = 8;
    public static inline var BACKWARD:Int = 16;
    
    public static function toString(type:Int):String {
        return switch(type) {
            case PERSIST: "PERSIST";
            case LOOPING: "LOOPING";
            case PINGPONG: "PINGPONG";
            case ONESHOT: "ONESHOT";
            case BACKWARD: "BACKWARD";
            default: "UNKNOWN";
        }
    }
}