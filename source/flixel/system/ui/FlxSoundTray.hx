package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
    /**
     * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
     */
    public var active:Bool;

    /**
     * Helps us auto-hide the sound tray after a volume change.
     */
    var _timer:Float;

    /**
     * Volume indicator ring
     */
    var _volumeRing:Shape;

    /**
     * How wide the sound tray background is.
     */
    var _width:Int = 70;

    var _defaultScale:Float = 2.0;

    /**The sound used when increasing the volume.**/
    public var volumeUpSound:String = "assets/sounds/volup";

    /**The sound used when decreasing the volume.**/
    public var volumeDownSound:String = 'assets/sounds/voldown';

    /**Whether or not changing the volume should make noise.**/
    public var silent:Bool = false;

    /**
	 * Ring params
	*/
    final RING_RADIUS:Float = 15;
    final RING_THICKNESS:Float = 8;
    final RING_CENTER_X:Float = 35; // horizontally
    final RING_CENTER_Y:Float = 20; // vertically

    /**
     * Sets up the "sound tray", the little volume meter that pops down sometimes.
     */
    @:keep
    public function new()
    {
        super();

        FlxG.sound.cache(volumeUpSound);
        FlxG.sound.cache(volumeDownSound);

        visible = false;
        scaleX = _defaultScale;
        scaleY = _defaultScale;
		//bg
        var tmp:Bitmap = new Bitmap(new BitmapData(_width, 52, true, 0x7F000000));
        screenCenter();
        addChild(tmp);

        var text:TextField = new TextField();
        text.width = tmp.width;
        text.height = tmp.height;
        text.multiline = true;
        text.wordWrap = true;
        text.selectable = false;

        #if flash
        text.embedFonts = true;
        text.antiAliasType = AntiAliasType.NORMAL;
        text.gridFitType = GridFitType.PIXEL;
        #else
        #end
		//ass text
        var dtf:TextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 10, 0xffffff);
        dtf.align = TextFormatAlign.CENTER;
        text.defaultTextFormat = dtf;
        addChild(text);
        text.text = "VOLUME";
        text.y = 38;

        _volumeRing = new Shape();
        addChild(_volumeRing);

        y = -height;
        visible = false;
    }

    /**
     * Draws a ring segment
     */
    function drawRing(shape:Shape, centerX:Float, centerY:Float, radius:Float, thickness:Float, 
                     startAngle:Float, endAngle:Float, color:FlxColor, alpha:Float = 1.0):Void
    {
        var g = shape.graphics;
        g.clear();
        
        if (endAngle <= startAngle) 
            return;
        
        // convert degrees to radians
        var startRad:Float = (startAngle - 90) * Math.PI / 180;
        var endRad:Float = (endAngle - 90) * Math.PI / 180;
        
        // draw ring using curveTo for sexy smoothness
        g.beginFill(color, alpha);
        var innerRadius = radius - thickness/2;
        var outerRadius = radius + thickness/2;
        
        // move to starting point on inner circle
        g.moveTo(
            centerX + Math.cos(startRad) * innerRadius,
            centerY + Math.sin(startRad) * innerRadius
        );
        
        // draw arc along outer circle
        for (i in 0...32)
        {
            var t = i / 31;
            var angle = startRad + t * (endRad - startRad);
            g.lineTo(
                centerX + Math.cos(angle) * outerRadius,
                centerY + Math.sin(angle) * outerRadius
            );
        }
        
        // same as above but inner circle
        for (i in 0...32)
        {
            var t = (31 - i) / 31;
            var angle = startRad + t * (endRad - startRad);
            g.lineTo(
                centerX + Math.cos(angle) * innerRadius,
                centerY + Math.sin(angle) * innerRadius
            );
        }
        
        g.endFill();
    }

    /**
     * This function updates the soundtray object.
     */
    public function update(MS:Float):Void
    {
        if (_timer > 0)
        {
            _timer -= (MS / 1000);
        }
        else if (y > -height)
        {
            // increased slide up speed cuz was very slow (from 1,5 to 0.5)
            y -= (MS / 1000) * height * 1.5;

            if (y <= -height)
            {
                visible = false;
                active = false;

                #if FLX_SAVE
                if (FlxG.save.isBound)
                {
                    FlxG.save.data.mute = FlxG.sound.muted;
                    FlxG.save.data.volume = FlxG.sound.volume;
                    FlxG.save.flush();
                }
                #end
            }
        }
    }

    /**
     * Makes the little volume tray slide out.
     *
     * @param	up Whether the volume is increasing.
     */
    public function show(up:Bool = false):Void
    {
        if (!silent)
        {
            var sound = FlxAssets.getSound(up ? volumeUpSound : volumeDownSound);
            if (sound != null)
                FlxG.sound.load(sound).play();
        }

        // reduced display time (from 1.0 to 0.7)
        _timer = 0.7;
        y = 0;
        visible = true;
        active = true;
        var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

        if (FlxG.sound.muted)
        {
            globalVolume = 0;
        }

        // draw volume ring (0-360 degrees)
        var volumeAngle:Float = 360 * (globalVolume / 10);
        drawRing(_volumeRing, RING_CENTER_X, RING_CENTER_Y, RING_RADIUS, RING_THICKNESS, 
                    0, volumeAngle, FlxColor.WHITE, 1.0);
    }

    public function screenCenter():Void
    {
        scaleX = _defaultScale;
        scaleY = _defaultScale;

        x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
    }
}
#end