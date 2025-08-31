package game.scripting;

import flixel.FlxG;

using StringTools;
using Lambda;

class HScriptGlobal {
	public static var globalScript:FunkinHScript;
	public static var globalScriptActive:Bool = false;

	public static var stateRedirectMap:Map<String, Bool> = new Map();
	
	public static function addGlobalScript() {
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')#if MODS_ALLOWED , Paths.mods('scripts/') #end];
		#if MODS_ALLOWED
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods('${Paths.currentModDirectory}/scripts/'));
		for(mod in Paths.getGlobalMods()) foldersToCheck.insert(0, Paths.mods('$mod/scripts/states/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if(sys.FileSystem.exists(folder))
			{
				for (file in sys.FileSystem.readDirectory(folder))
				{
					#if HSCRIPT_ALLOWED
					if (file.endsWith('Global.hx') || file.endsWith('global.hx')) {
						globalScript = new FunkinHScript(folder + file);
						globalScriptActive = true;

                        break; //We only want one global script active at a time, Usually the upmost important mod that's enabled.
					}
					#end
				}
			}
		}
		
		if(globalScriptActive) {
			FlxG.signals.postGameStart.add(() -> globalScript?.call("onGameStart", []));
			FlxG.signals.preGameReset.add(() -> globalScript?.call("onGameReset", []));
			FlxG.signals.postGameReset.add(() -> globalScript?.call("onGameResetPost", []));
			FlxG.signals.preStateSwitch.add(() -> globalScript?.call("onStateSwitch", []));
			FlxG.signals.postStateSwitch.add(() -> globalScript?.call("onStateSwitchPost", []));
			FlxG.signals.preStateCreate.add((state:flixel.FlxState) -> globalScript?.call("onStateCreate", [state]));
			FlxG.signals.preDraw.add(() -> globalScript?.call("onDraw", []));
			FlxG.signals.postDraw.add(() -> globalScript?.call("onDrawPost", []));
			FlxG.signals.preUpdate.add(() -> globalScript?.call("onUpdate", [flixel.FlxG.elapsed]));
			FlxG.signals.postUpdate.add(() -> globalScript?.call("onUpdatePost", [flixel.FlxG.elapsed]));
			FlxG.signals.focusGained.add(() -> globalScript?.call("onFocusGained", []));
			FlxG.signals.focusLost.add(() -> globalScript?.call("onFocusLost", []));
			FlxG.signals.gameResized.add((w:Int, h:Int) -> globalScript?.call("onGameResized", [w, h]));
			
			globalScript?.call("onCreatePost", []);
		}
	}

	public static function setSoftcodedState(stateClassName:String, value:Bool):Void
	{
		#if (HSCRIPT_ALLOWED && SCRIPTABLE_STATES)
		if (globalScriptActive && globalScript != null)
		{
			callGlobalScript("setSoftcodedState", [stateClassName, value]);
		}
		#end
	}
	
	public static function callGlobalScript(callback:String, args:Array<Dynamic>):Dynamic {
		if(globalScriptActive) return globalScript?.call(callback, args);
		return null;
	}
	
	public static function destroyModScript() {
		if(globalScriptActive) {
			globalScript?.call("onDestroy", []);
			globalScript?.stop();
			globalScript = null;
			
			globalScriptActive = false;
		}
	}
}