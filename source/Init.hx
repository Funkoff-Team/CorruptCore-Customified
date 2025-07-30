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
        #if (LUA_ALLOWED && MODS_ALLOWED)
		Paths.pushGlobalMods();
		WeekData.loadTheFirstEnabledMod();
		#end

        FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;

        FlxG.fixedTimestep = false;
	    FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;
        FlxG.keys.preventDefaultKeys = [TAB];

        #if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

        PlayerSettings.init();

        FlxG.save.bind('ccengine', 'justinx');

		ClientPrefs.loadPrefs();

        Highscore.load();

        #if GLOBAL_SCRIPTS
		if(!hscript.ScriptGlobal.globalScriptActive) hscript.ScriptGlobal.addGlobalScript();
		#end

		FlxG.switchState(new TitleState());
    }
}