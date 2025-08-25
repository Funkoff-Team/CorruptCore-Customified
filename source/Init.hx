package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;

class Init extends FlxState
{
    public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

    override function create()
    {
		PlayerSettings.init();

        FlxG.save.bind('ccengine', CoolUtil.getSavePath());

		ClientPrefs.init();

		Highscore.load();

		if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

		if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
			
        #if (LUA_ALLOWED && MODS_ALLOWED)
		Paths.pushGlobalMods();
		WeekData.loadTheFirstEnabledMod();
		#end

        FlxG.fixedTimestep = false;
	    FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;
        FlxG.keys.preventDefaultKeys = [TAB];

        #if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

        #if GLOBAL_SCRIPTS
		if(!game.scripting.HScriptGlobal.globalScriptActive) game.scripting.HScriptGlobal.addGlobalScript();
		#end

		FlxG.switchState(() -> new TitleState());
    }
}