package flixel;

import flixel.FlxG;
import flixel.system.scaleModes.BaseScaleMode;

/**
 * Scale mode that allows for wide screen support.
 * Rewritten bcuz old code looks weird imo
 */

class FlxScaleMode extends BaseScaleMode
{
    public static var allowWideScreen(default, set):Bool = true;
    
    override function updateGameSize(Width:Int, Height:Int):Void
    {
        if (shouldUseWideScreen())
        {
            super.updateGameSize(Width, Height);
        }
        else
        {
            final targetRatio = FlxG.width / FlxG.height;
            final screenRatio = Width / Height;
            
            if (screenRatio < targetRatio)
                gameSize.set(Width, Math.floor(Width / targetRatio));
            else
                gameSize.set(Math.floor(Height * targetRatio), Height);
        }
    }

    override function updateGamePosition():Void
    {
        if (shouldUseWideScreen())
        {
            FlxG.game.x = 0;
            FlxG.game.y = 0;
        }
        else
        {
            super.updateGamePosition();
        }
    }

    static function set_allowWideScreen(value:Bool):Bool
    {
        if (allowWideScreen == value) return value;
            
        allowWideScreen = value;
        resetScaleMode();
        return value;
    }

	//better than copying this booleans several time
    static inline function shouldUseWideScreen():Bool return ClientPrefs.noBordersScreen && allowWideScreen;

    static function resetScaleMode()
    {
        var currentType = Type.getClass(FlxG.scaleMode);
        FlxG.scaleMode = Type.createInstance(currentType, []);
    }
}