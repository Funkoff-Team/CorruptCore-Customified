package game.states.backend;

import game.objects.FNFCamera;
import game.backend.Conductor.BPMChangeEvent;
import game.scripting.FunkinLua;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.FlxBasic;
#if sys
import sys.FileSystem;
#end
#if SCRIPTABLE_STATES
import hscript.HScript;
#end

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	var _fnfCameraInitialized:Bool = false;

	public static var timePassedOnState:Float = 0;

	//hscript
	public var className:String = "";
	public var useCustomStateName:Bool = false;

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		if(!_fnfCameraInitialized) initFNFCamera();

		CustomFadeTransition.nextCamera = FlxG.camera;

		var colorBlindType = ClientPrefs.colorBlindMode;
		var intensity = ClientPrefs.colorBlindIntensity;
		var index = ['None', 'Deutranopia', 'Protanopia', 'Tritanopia', 'Protanomaly', 'Deuteranomaly', 'Tritanomaly', 'Rod monochromacy', 'Cone monochromacy'].indexOf(colorBlindType);
		if (index == -1) index = -1;
		Main.updateColorblindFilter(index - 1, intensity);

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;

		runStateFiles((useCustomStateName ? className : Type.getClassName(Type.getClass(this))));

		super.create();

		quickCallMenuScript("onCreatePost", []);
	}

	public function initFNFCamera():FNFCamera
	{
		var camera = new FNFCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_fnfCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		/*if (Main.colorblindMode != -1) {
			Main.applyColorblindFilterToCamera(camera, Main.colorblindMode, Main.colorblindIntensity);
		}*/

		return camera;
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		quickCallMenuScript("onUpdate", [elapsed]);

		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);

		quickCallMenuScript("onUpdatePost", [elapsed]);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(() -> nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null) nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(() -> nextState);
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	public var stages:Array<BaseStage> = [];
	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();

		quickCallMenuScript("onStepHit", []);
	}

	public function beatHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
		//trace('Beat: ' + curBeat);
		quickCallMenuScript("onBeatHit", []);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
		quickCallMenuScript("onSectionHit", []);
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	/*
	* HScript things
	*/
	#if SCRIPTABLE_STATES
	override public function openSubState(subState:FlxSubState) 
	{
		if(quickCallMenuScript("onOpenSubState", [subState]) != FunkinLua.Function_Stop) super.openSubState(subState);
	}
	
	override public function onResize(w:Int, h:Int) {
		super.onResize(w, h);
		quickCallMenuScript("onResize", [w, h]);
	}
	
	override public function draw() 
	{
		if(quickCallMenuScript("onDraw", []) != FunkinLua.Function_Stop) super.draw();
		quickCallMenuScript("onDrawPost", []);
	}
	
	override public function onFocus() {
		super.onFocus();
		quickCallMenuScript("onFocus", []);
	}

	override public function onFocusLost() {
		super.onFocusLost();
		quickCallMenuScript("onFocusLost", []);
	}
	
	override function destroy() {
		for (sc in menuScriptArray) {
			sc.call("onDestroy", []);
			sc.stop();
		}
		menuScriptArray = [];
		
		super.destroy();
	}
	#end
	
	#if SCRIPTABLE_STATES
	public var menuScriptArray:Array<HScript> = [];
	public var scriptsAllowed:Bool = true;
	#end
	public function runStateFiles(statePath:String) {
		#if SCRIPTABLE_STATES
		if(!scriptsAllowed) return;

		var filesPushed = [];
		
		var scriptPaths = Paths.getStateScripts(statePath);
		
		for (folder in scriptPaths)
		{
			if(FileSystem.exists(folder) && FileSystem.isDirectory(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					#if HSCRIPT_ALLOWED
					if (file.endsWith('.hx') && !filesPushed.contains(file)) {
						var fullPath = folder + file;
						menuScriptArray.push(new HScript(fullPath));
						filesPushed.push(file);
					}
					#else
					break;
					#end
				}
			}
			else if (FileSystem.exists(folder + '.hx'))
			{
				var fullPath = folder + '.hx';
				if(!filesPushed.contains(fullPath)) {
					menuScriptArray.push(new HScript(fullPath));
					filesPushed.push(fullPath);
				}
			}
		}
		#end
	}
	public function setOnMenuScript(variable:String, arg:Dynamic) {
		#if SCRIPTABLE_STATES
		if(!scriptsAllowed) return;
		for (script in menuScriptArray) {
			script.set(variable, arg);
		}
		#end
	}
	
	public function quickCallMenuScript(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal = FunkinLua.Function_Continue;
		#if SCRIPTABLE_STATES
		if(!scriptsAllowed) return returnVal;
		for (sc in menuScriptArray) {
			var myValue = sc.call(event, args);
			if(myValue == FunkinLua.Function_StopLua) break;
			if(myValue != null && myValue != FunkinLua.Function_Continue) returnVal = myValue;
		}
		#end
		return returnVal;
	}
	
	public function callOnMenuScript(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = FunkinLua.Function_Continue;
		#if SCRIPTABLE_STATES
		if(!scriptsAllowed) return returnVal;
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (sc in menuScriptArray) {
			if(exclusions.contains(sc.scriptName))
				continue;

			var myValue = sc.call(event, args);
			if(myValue == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			if(myValue != null && myValue != FunkinLua.Function_Continue) {
				returnVal = myValue;
			}
		}
		#end
		return returnVal;
	}
}