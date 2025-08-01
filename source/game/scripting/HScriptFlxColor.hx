package game.scripting;

import flixel.util.FlxColor;

class HScriptFlxColor {
    //Color constants
    public static inline var TRANSPARENT:Int = FlxColor.TRANSPARENT;
    public static inline var WHITE:Int = FlxColor.WHITE;
    public static inline var GRAY:Int = FlxColor.GRAY;
    public static inline var BLACK:Int = FlxColor.BLACK;
    public static inline var GREEN:Int = FlxColor.GREEN;
    public static inline var LIME:Int = FlxColor.LIME;
    public static inline var YELLOW:Int = FlxColor.YELLOW;
    public static inline var ORANGE:Int = FlxColor.ORANGE;
    public static inline var RED:Int = FlxColor.RED;
    public static inline var PURPLE:Int = FlxColor.PURPLE;
    public static inline var BLUE:Int = FlxColor.BLUE;
    public static inline var BROWN:Int = FlxColor.BROWN;
    public static inline var PINK:Int = FlxColor.PINK;
    public static inline var MAGENTA:Int = FlxColor.MAGENTA;
    public static inline var CYAN:Int = FlxColor.CYAN;
    
    //Factory methods
    public static inline function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
        return FlxColor.fromRGB(Red, Green, Blue, Alpha);
    
    public static inline function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
        return FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
    
    public static inline function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
        return FlxColor.fromHSB(Hue, Sat, Brt, Alpha);
    
    public static inline function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
        return FlxColor.fromHSL(Hue, Sat, Light, Alpha);
    
    public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
        return FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);
    
    public static inline function fromInt(Value:Int):Int
        return FlxColor.fromInt(Value);
    
    public static function fromString(str:String):Null<Int> {
        var result = FlxColor.fromString(str);
        return result != null ? result.to24Bit() : null;
    }
    
    //Utility methods
    public static inline function interpolate(Color1:Int, Color2:Int, Factor:Float = 0.5):Int
        return FlxColor.interpolate(Color1, Color2, Factor);
    
    public static function gradient(Color1:Int, Color2:Int, Steps:Int, ?Ease:Float->Float):Array<Int> {
        var colors = FlxColor.gradient(Color1, Color2, Steps, Ease);
        return [for (c in colors) c];
    }
    
    public static function getHSBColorWheel(Alpha:Int = 255):Array<Int> {
        var colors = FlxColor.getHSBColorWheel(Alpha);
        return [for (c in colors) c];
    }
    
    //Component getters
    public static inline function getRed(color:Int):Int
        return (color >> 16) & 0xFF;
    
    public static inline function getGreen(color:Int):Int
        return (color >> 8) & 0xFF;
    
    public static inline function getBlue(color:Int):Int
        return color & 0xFF;
    
    public static inline function getAlpha(color:Int):Int
        return (color >> 24) & 0xFF;
}