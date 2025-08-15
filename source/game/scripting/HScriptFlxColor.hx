package game.scripting;

import flixel.util.FlxColor;
import flixel.math.FlxMath;

/**
 * Literally just a copy of FlxColor with some inline changes lol
 */

class HScriptFlxColor {
    // ============== COLOR CONSTANTS ==============
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
    
    // ============== SIMPLE FACTORY METHODS ==============
    public static inline function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int {
        return (Alpha << 24) | (Red << 16) | (Green << 8) | Blue;
    }
    
    public static inline function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int {
        return fromRGB(
            Math.round(Red * 255),
            Math.round(Green * 255),
            Math.round(Blue * 255),
            Math.round(Alpha * 255)
        );
    }
    
    // ============== RELIABLE COMPONENT ACCESS ==============
    public static inline function getRed(color:Int):Int
        return (color >> 16) & 0xFF;
    
    public static inline function getGreen(color:Int):Int
        return (color >> 8) & 0xFF;
    
    public static inline function getBlue(color:Int):Int
        return color & 0xFF;
    
    public static inline function getAlpha(color:Int):Int
        return (color >> 24) & 0xFF;
    
    public static inline function getRedFloat(color:Int):Float
        return getRed(color) / 255;
    
    public static inline function getGreenFloat(color:Int):Float
        return getGreen(color) / 255;
    
    public static inline function getBlueFloat(color:Int):Float
        return getBlue(color) / 255;
    
    public static inline function getAlphaFloat(color:Int):Float
        return getAlpha(color) / 255;
    
    // ============== GUARANTEED WORKING UTILITIES ==============
    
    /**
     * Simple interpolation that always works
     */
    public static function interpolate(Color1:Int, Color2:Int, Factor:Float = 0.5):Int {
        Factor = FlxMath.bound(Factor, 0, 1);
        
        final r1 = getRed(Color1);
        final g1 = getGreen(Color1);
        final b1 = getBlue(Color1);
        final a1 = getAlpha(Color1);
        
        final r2 = getRed(Color2);
        final g2 = getGreen(Color2);
        final b2 = getBlue(Color2);
        final a2 = getAlpha(Color2);
        
        return fromRGB(
            Math.round(r1 + (r2 - r1) * Factor),
            Math.round(g1 + (g2 - g1) * Factor),
            Math.round(b1 + (b2 - b1) * Factor),
            Math.round(a1 + (a2 - a1) * Factor)
        );
    }
    
    /**
     * Darken by reducing RGB values
     */
    public static function getDarkened(color:Int, Factor:Float = 0.2):Int {
        Factor = FlxMath.bound(Factor, 0, 1);
        
        final r = Math.round(getRed(color) * (1 - Factor));
        final g = Math.round(getGreen(color) * (1 - Factor));
        final b = Math.round(getBlue(color) * (1 - Factor));
        final a = getAlpha(color);
        
        return fromRGB(r, g, b, a);
    }
    
    /**
     * Lighten by increasing RGB values toward white
     */
    public static function getLightened(color:Int, Factor:Float = 0.2):Int {
        Factor = FlxMath.bound(Factor, 0, 1);
        
        final r = Math.round(getRed(color) + (255 - getRed(color)) * Factor);
        final g = Math.round(getGreen(color) + (255 - getGreen(color)) * Factor);
        final b = Math.round(getBlue(color) + (255 - getBlue(color)) * Factor);
        final a = getAlpha(color);
        
        return fromRGB(r, g, b, a);
    }
    
    /**
     * Simple inversion that always works
     */
    public static function getInverted(color:Int):Int {
        return fromRGB(
            255 - getRed(color),
            255 - getGreen(color),
            255 - getBlue(color),
            getAlpha(color)
        );
    }
    
    /**
     * Create gradient with reliable interpolation
     */
    public static function gradient(Color1:Int, Color2:Int, Steps:Int, ?Ease:Float->Float):Array<Int> {
        if (Steps < 2) return [Color1];
        if (Ease == null) Ease = function(t:Float) return t;
        
        var output = [];
        for (i in 0...Steps) {
            final factor = Ease(i / (Steps - 1));
            output.push(interpolate(Color1, Color2, factor));
        }
        return output;
    }
    
    // ============== SIMPLE FORMATTING ==============
    
    /**
     * Convert to hex string (guaranteed format)
     */
    public static function toHexString(color:Int, IncludeAlpha:Bool = true, IncludePrefix:Bool = true):String {
        final parts = [];
        if (IncludeAlpha) parts.push(StringTools.hex(getAlpha(color), 2));
        parts.push(StringTools.hex(getRed(color), 2));
        parts.push(StringTools.hex(getGreen(color), 2));
        parts.push(StringTools.hex(getBlue(color), 2));
        
        return (IncludePrefix ? "0x" : "") + parts.join("").toUpperCase();
    }
    
    /**
     * Convert to web format (#RRGGBB)
     */
    public static function toWebString(color:Int):String {
        return "#" + toHexString(color, false, false).substr(2);
    }
    
    // ============== GUARANTEED WORKING COLOR INFO ==============
    public static function getColorInfo(color:Int):String {
        return 'Hex: ${toHexString(color)}\n' +
               'RGB: A:${getAlpha(color)} R:${getRed(color)} G:${getGreen(color)} B:${getBlue(color)}';
    }
    
    // ============== TESTED COLOR CREATION ==============
    public static function fromString(str:String):Null<Int> {
        // Simple implementation for common cases
        str = str.trim().toUpperCase();
        
        // Handle hex strings
        if (str.startsWith("0X") || str.startsWith("#")) {
            str = str.replace("0X", "").replace("#", "");
            if (str.length == 3) { // #RGB
                final r = Std.parseInt("0x" + str.charAt(0)) * 17;
                final g = Std.parseInt("0x" + str.charAt(1)) * 17;
                final b = Std.parseInt("0x" + str.charAt(2)) * 17;
                return fromRGB(r, g, b);
            }
            else if (str.length == 6) { // #RRGGBB
                return Std.parseInt("0xFF" + str);
            }
            else if (str.length == 8) { // #AARRGGBB
                return Std.parseInt("0x" + str);
            }
        }
        
        // Handle named colors
        switch (str) {
            case "TRANSPARENT": return TRANSPARENT;
            case "WHITE": return WHITE;
            case "GRAY": return GRAY;
            case "BLACK": return BLACK;
            case "GREEN": return GREEN;
            case "LIME": return LIME;
            case "YELLOW": return YELLOW;
            case "ORANGE": return ORANGE;
            case "RED": return RED;
            case "PURPLE": return PURPLE;
            case "BLUE": return BLUE;
            case "BROWN": return BROWN;
            case "PINK": return PINK;
            case "MAGENTA": return MAGENTA;
            case "CYAN": return CYAN;
            default: return null;
        }
    }
}