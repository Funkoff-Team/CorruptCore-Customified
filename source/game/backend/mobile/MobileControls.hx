package game.backend.mobile;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import game.backend.mobile.flixel.FlxHitbox;
import game.backend.mobile.flixel.FlxVirtualPad;

/**
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class MobileControls extends FlxSpriteGroup
{
	public static var customVirtualPad(get, set):FlxVirtualPad;
	public static var mode(get, set):String;

	public var _virtualpad:FlxVirtualPad;
	public var hitbox:FlxHitbox;

	//public var shutYoAss = FlxHitbox.buttonDodge;

	public function new(usesDodge:Bool = false)
	{
		super();

		switch (MobileControls.mode)
		{
			case 'Pad-Right':
				_virtualpad = new FlxVirtualPad(RIGHT_FULL, NONE);
				add(_virtualpad);
			case 'Pad-Left':
				_virtualpad = new FlxVirtualPad(LEFT_FULL, NONE);
				add(_virtualpad);
			case 'Pad-Custom':
				_virtualpad = MobileControls.customVirtualPad;
				add(_virtualpad);
			case 'Pad-Duo':
				_virtualpad = new FlxVirtualPad(BOTH_FULL, NONE);
				add(_virtualpad);
			case 'Hitbox':
			    if (usesDodge) {
				    hitbox = new FlxHitbox(SPACE);
			    } else {
			        hitbox = new FlxHitbox(DEFAULT);
			    }
				add(hitbox);
			case 'Keyboard': // do nothing
		}
	}

	override public function destroy():Void
	{
		super.destroy();

		if (_virtualpad != null)
			_virtualpad = FlxDestroyUtil.destroy(_virtualpad);

		if (hitbox != null)
			hitbox = FlxDestroyUtil.destroy(hitbox);
	}

	private static function get_mode():String
	{
		if (FlxG.save.data.controlsMode == null)
		{
			FlxG.save.data.controlsMode = 'Hitbox';
			FlxG.save.flush();
		}

		return FlxG.save.data.controlsMode;
	}

	private static function set_mode(mode:String = 'Hitbox'):String
	{
		FlxG.save.data.controlsMode = mode;
		FlxG.save.flush();

		return mode;
	}

	private static function get_customVirtualPad():FlxVirtualPad
	{
		var _virtualpad:FlxVirtualPad = new FlxVirtualPad(RIGHT_FULL, NONE);
		if (FlxG.save.data.buttons == null)
			return _virtualpad;

		var tempCount:Int = 0;
		for (buttons in _virtualpad)
		{
			buttons.x = FlxG.save.data.buttons[tempCount].x;
			buttons.y = FlxG.save.data.buttons[tempCount].y;
			tempCount++;
		}

		return _virtualpad;
	}

	private static function set_customVirtualPad(_virtualpad:FlxVirtualPad):FlxVirtualPad
	{
		if (FlxG.save.data.buttons == null)
		{
			FlxG.save.data.buttons = new Array();
			for (buttons in _virtualpad)
			{
				FlxG.save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
				FlxG.save.flush();
			}
		}
		else
		{
			var tempCount:Int = 0;
			for (buttons in _virtualpad)
			{
				FlxG.save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				FlxG.save.flush();
				tempCount++;
			}
		}

		return _virtualpad;
	}
}
