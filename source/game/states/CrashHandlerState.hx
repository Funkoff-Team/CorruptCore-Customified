package game.states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class CrashHandlerState extends MusicBeatState
{	
	final warningMessage:String;
	
	final continueCallback:Void->Void;
	
	public function new(warningMessage:String, continueCallback:Void->Void)
	{
		this.continueCallback = continueCallback;
		this.warningMessage = warningMessage;
		super();
	}
	
	override function create()
	{
		@:nullSafety(Off)
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.sound.playMusic(Paths.music("NO-WAY!"));
		
		var error = new FlxText(0, 0, 0, 'ERROR HAS OCCURED!', 46);
		error.setFormat(Paths.font('vcr.ttf'), 46, FlxColor.RED, LEFT, OUTLINE, FlxColor.BLACK);
		error.screenCenter(X);
		error.y = 25;
		add(error);
		
		var text = new FlxText(25, 0, FlxG.width - 50, warningMessage, 32);
		text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(text);
		text.screenCenter(Y);
		
		var text = new FlxText(0, FlxG.height - 25 - 32, FlxG.width, 'Press ACCEPT to go to main menu.', 32);
		text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(text);

		FlxTween.tween(error, {y: error.y + 45}, 2, {ease: FlxEase.sineInOut, type: PINGPONG});
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.ACCEPT)
		{
			persistentUpdate = false;
			FlxG.sound.playMusic(Paths.music("freakyMenu"));
			continueCallback();
		}
	}
}