package game.scripting;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.geom.Point;
import openfl.geom.Vector3D;

class HScriptFlxPoint {
    //Factory methods
    public static inline function get(x:Float = 0, y:Float = 0):FlxPoint 
        return FlxPoint.get(x, y);
    
    public static inline function weak(x:Float = 0, y:Float = 0):FlxPoint 
        return FlxPoint.weak(x, y);
    
    //Conversion methods
    public static function fromVector(v:Vector3D):FlxPoint 
        return FlxPoint.get(v.x, v.y);
    
    public static function fromFlashPoint(p:Point):FlxPoint 
        return FlxPoint.get(p.x, p.y);
    
    public static function fromBoundingBox(rect:FlxRect, ?point:FlxPoint):FlxPoint {
        if (point == null) point = FlxPoint.get();
        return point.set(rect.x, rect.y);
    }
    
    //Constants (return new instances)
    public static var ZERO(get, never):FlxPoint;
    private static inline function get_ZERO():FlxPoint 
        return FlxPoint.get(0, 0);
    
    public static var ONE(get, never):FlxPoint;
    private static inline function get_ONE():FlxPoint 
        return FlxPoint.get(1, 1);
    
    public static var POINT_UP(get, never):FlxPoint;
    private static inline function get_POINT_UP():FlxPoint 
        return FlxPoint.get(0, -1);
    
    public static var POINT_DOWN(get, never):FlxPoint;
    private static inline function get_POINT_DOWN():FlxPoint 
        return FlxPoint.get(0, 1);
    
    public static var POINT_LEFT(get, never):FlxPoint;
    private static inline function get_POINT_LEFT():FlxPoint 
        return FlxPoint.get(-1, 0);
    
    public static var POINT_RIGHT(get, never):FlxPoint;
    private static inline function get_POINT_RIGHT():FlxPoint 
        return FlxPoint.get(1, 0);
    
    //Utility methods
    public static inline function distanceBetween(pointA:FlxPoint, pointB:FlxPoint):Float 
        return pointA.distanceTo(pointB);
    
    public static inline function angleBetween(pointA:FlxPoint, pointB:FlxPoint):Float 
        return pointA.degreesTo(pointB);
    
    public static inline function addPoints(pointA:FlxPoint, pointB:FlxPoint):FlxPoint 
        return pointA.addPoint(pointB);
    
    public static inline function subtractPoints(pointA:FlxPoint, pointB:FlxPoint):FlxPoint 
        return pointA.subtractPoint(pointB);
    
    public static inline function dotProduct(pointA:FlxPoint, pointB:FlxPoint):Float 
        return pointA.dot(pointB);
    
    public static inline function crossProductLength(pointA:FlxPoint, pointB:FlxPoint):Float 
        return pointA.crossProductLength(pointB);
    
    //Memory management
    public static inline function put(p:FlxPoint):Void 
        p.put();
    
    public static inline function putWeak(p:FlxPoint):Void 
        p.putWeak();
}