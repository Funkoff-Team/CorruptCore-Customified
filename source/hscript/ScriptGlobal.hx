package hscript;

using StringTools;

class ScriptGlobal {
	public static var globalScript:HScript;
	public static var globalScriptActive:Bool = false;
	
	public static function addGlobalScript() {
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')#if MODS_ALLOWED , Paths.mods('scripts/') #end];
		#if MODS_ALLOWED
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		for(mod in Paths.getGlobalMods()) foldersToCheck.insert(0, Paths.mods(mod + '/scripts/states/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if(sys.FileSystem.exists(folder))
			{
				for (file in sys.FileSystem.readDirectory(folder))
				{
					#if HSCRIPT_ALLOWED
					if (file.endsWith('Global.hx')) {
						globalScript = new HScript(folder + file);
						globalScriptActive = true;
						break; //We only want one global script active at a time, Usually the upmost important mod that's enabled.
					}
					#end
				}
			}
		}
		
		if(globalScriptActive && globalScript != null) {
			FlxG.signals.focusGained.add(function() {
				if(globalScriptActive) globalScript.call("onFocusGained", []);
			});
			
			FlxG.signals.focusLost.add(function() {
				if(globalScriptActive) globalScript.call("onFocusLost", []);
			});
			
			FlxG.signals.gameResized.add(function(width:Int, height:Int) {
				if(globalScriptActive) globalScript.call("onGameResized", [width, height]);
			});
			
			FlxG.signals.postGameStart.add(function() {
				if(globalScriptActive) globalScript.call("onGameStart", []);
			});
			
			FlxG.signals.preGameReset.add(function() {
				if(globalScriptActive) globalScript.call("onGameReset", []);
			});
			
			FlxG.signals.postGameReset.add(function() {
				if(globalScriptActive) globalScript.call("onGameResetPost", []);
			});
			
			FlxG.signals.preStateSwitch.add(function() {
				if(globalScriptActive) globalScript.call("onStateSwitch", []);
			});
			
			FlxG.signals.postStateSwitch.add(function() {
				if(globalScriptActive) globalScript.call("onStateSwitchPost", []);
			});
			
			FlxG.signals.preStateCreate.add(function(state:flixel.FlxState) {
				if(globalScriptActive) globalScript.call("onStateCreate", [state]);
			});

			//Update signals (Hopefully it doesn't lag the game out)
			
			FlxG.signals.preDraw.add(function() {
				if(globalScriptActive) globalScript.call("onDraw", []);
			});
			
			FlxG.signals.postDraw.add(function() {
				if(globalScriptActive) globalScript.call("onDrawPost", []);
			});
			
			FlxG.signals.preUpdate.add(function() {
				if(globalScriptActive) globalScript.call("onUpdate", [flixel.FlxG.elapsed]);
			});
			
			FlxG.signals.postUpdate.add(function() {
				if(globalScriptActive) globalScript.call("onUpdatePost", [flixel.FlxG.elapsed]);
			});
			
			//
			
			globalScript.call("onCreatePost", []);
		}
	}
	
	public static function callGlobalScript(callback:String, args:Array<Dynamic>):Dynamic {
		if(globalScript != null && globalScriptActive) return globalScript.call(callback, args);
		return null;
	}
	
	public static function destroyModScript() {
		if(globalScript != null && globalScriptActive) {
			globalScript.call("onDestroy", []);
			globalScript.stop();
			globalScript = null;
			
			globalScriptActive = false;
		}
	}
}