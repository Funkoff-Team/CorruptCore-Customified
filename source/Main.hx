package;

#if desktop
import api.Discord.DiscordClient;
#end
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import openfl.filters.ColorMatrixFilter;
import openfl.events.UncaughtErrorEvent;
import openfl.errors.Error;

//crash handler stuff
#if !CRASH_HANDLER
import CrashHandler;
#end

using StringTools;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: Init, // initial game state
        zoom: -1, // If -1, zoom is automatically calculated to fit the window dimensions.
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPS;

	//for colorblind mode
	public static var colorblindMode:Int = -1;
	public static var colorblindIntensity:Float = 1.0;

	// You can pretty much ignore everything from here on - your code should go in your game.states.
	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
        cpp.NativeGc.enable(true);
        cpp.vm.Gc.run(true);
        #elseif hl
        hl.Gc.enable(true);
        #end
	}

	public function new()
	{
		super();

		#if !CRASH_HANDLER
	    CrashHandler.init();
	    #else
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#end

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		// was taken from doido engine
		// thanks @nebulazorua, @crowplexus, @diogotvv
		FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e) ->
		{
			if (e.keyCode == FlxKey.F11)
				FlxG.fullscreen = !FlxG.fullscreen;
			
			if (e.keyCode == FlxKey.ENTER && e.altKey)
				e.stopImmediatePropagation();
		}, false, 100);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		#if (openfl < '9.2.0')
        var stageWidth:Int = Lib.current.stage.stageWidth;
	    var stageHeight:Int = Lib.current.stage.stageHeight;

	    if (game.zoom == -1)
	    {
		    var ratioX:Float = stageWidth / game.width;
		    var ratioY:Float = stageHeight / game.height;
		    game.zoom = Math.min(ratioX, ratioY);
		    game.width = Math.ceil(stageWidth / game.zoom);
		    game.height = Math.ceil(stageHeight / game.zoom);
	    }
        #elseif (openfl >= '9.2.0')
        if (game.zoom == -1) {
            game.zoom = 1;
        }
	    #end

        #if (cpp && windows)
		lime.Native.fixScaling();
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end
	
		ClientPrefs.loadDefaultKeys();

		#if CRASH_HANDLER
		addChild(new FunkinGame(game.width, game.height, Init, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		#else
		addChild(new FlxGame(game.width, game.height, Init, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		#end

		pluginsLessGo();

		FlxG.scaleMode = new flixel.FlxScaleMode();

		#if !mobile
		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}
		#end

		FlxG.signals.gameResized.add((w, h) -> {
            if (fpsVar != null)
                fpsVar.positionFPS(10, 3, Math.min(w / FlxG.width, h / FlxG.height));

			resetSpriteCache(this);

            if (FlxG.cameras != null && FlxG.cameras.list != null) {
                for (cam in FlxG.cameras.list) {
                    if (cam != null)
                        resetSpriteCache(cam.flashSprite);
                }
            }

            if (FlxG.game != null)
                resetSpriteCache(FlxG.game);
        });

		#if desktop
		if(CoolUtil.hasVersion("Windows 10")) {
			FlxG.stage.window.borderless = true;
			FlxG.stage.window.borderless = false;
		}
		#end

		/*#if desktop
		DiscordClient.prepare();
		#end*/
	}

	private static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			if (sprite != null)
			{
		   		sprite.__cacheBitmapData = null;
				sprite.__cacheBitmapData2 = null;
				sprite.__cacheBitmapData3 = null;
				sprite.__cacheBitmapColorTransform = null;
			}
		}
    }

    #if (cpp || hl)
    private static function onError(message:Dynamic):Void
    {
        throw Std.string(message);
    }
    #end
	
    public function getFPS():Float {
	    return fpsVar.currentFPS;	
    }

	private function onUncaughtError(e:UncaughtErrorEvent):Void
    {
        e.preventDefault();
        handleCrash(e.error);
    }

	public static function handleCrash(e:Dynamic):Void
    {
        var emsg:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					emsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
					trace(stackItem);
			}
		}
		
		final crashReport = 'Error caught: ' + e.message + '\nLines:\n' + emsg;
		
		FlxG.switchState(new game.states.CrashHandlerState(crashReport, () -> FlxG.switchState(() -> new MainMenuState())));
    }

	public static function applyColorblindFilterToCamera(camera:FlxCamera, type:Int, intensity:Float = 1) {
		camera.filters = [];
		if (type == -1) return;

		var matrixShit = getColorblindMatrix(type, intensity);
		var filter = new ColorMatrixFilter(matrixShit);
		camera.filters = [filter];
	}

	private static function getColorblindMatrix(type:Int, intensity:Float):Array<Float> {
		var matrixShit:Array<Float> = [];
		switch (type) {
			case 0: // Deuteranopia
				matrixShit = [
					0.625, 0.375, 0, 0, 0,
					0.700, 0.300, 0, 0, 0,
					0,     0.300, 0.700, 0, 0,
					0, 0, 0, 1, 0];
					
			case 1: // Protanopia
				matrixShit = [
					0.567, 0.433, 0, 0, 0,
					0.558, 0.442, 0, 0, 0,
					0,     0.242, 0.758, 0, 0,
					0, 0, 0, 1, 0];
					
			case 2: // Tritanopia
				matrixShit = [
					0.950, 0.050, 0, 0, 0,
					0,     0.433, 0.567, 0, 0,
					0,     0.475, 0.525, 0, 0,
					0, 0, 0, 1, 0];
			
			case 3: // Protanomaly
				matrixShit = [
					0.817, 0.183, 0, 0, 0,
					0.333, 0.667, 0, 0, 0,
					0,     0.125, 0.875, 0, 0,
					0, 0, 0, 1, 0];
					
			case 4: // Deuteranomaly
				matrixShit = [
					0.800, 0.200, 0, 0, 0,
					0.258, 0.742, 0, 0, 0,
					0,     0.142, 0.858, 0, 0,
					0, 0, 0, 1, 0];
					
			case 5: // Tritanomaly
				matrixShit = [
					0.967, 0.033, 0, 0, 0,
					0,     0.733, 0.267, 0, 0,
					0,     0.183, 0.817, 0, 0,
					0, 0, 0, 1, 0];
			
			case 6: // Rod monochromacy
				matrixShit = [
					0.2126, 0.7152, 0.0722, 0, 0,
					0.2126, 0.7152, 0.0722, 0, 0,
					0.2126, 0.7152, 0.0722, 0, 0,
					0,      0,      0,      1, 0];
					
			case 7: // Cone monochromacy
				matrixShit = [
					0.299, 0.587, 0.114, 0, 0,
					0.299, 0.587, 0.114, 0, 0,
					0.299, 0.587, 0.114, 0, 0,
					0,     0,     0,     1, 0];
		}

		if (intensity < 1) {
			var identity = [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0];
			for (i in 0...matrixShit.length) {
				matrixShit[i] = matrixShit[i] * intensity + identity[i] * (1 - intensity);
			}
		}
		return matrixShit;
	}

	public static function updateColorblindFilter(type:Int = -1, intensity:Float = 1) {
		colorblindMode = type;
		colorblindIntensity = intensity;
		
		for (camera in FlxG.cameras.list) {
			applyColorblindFilterToCamera(camera, type, intensity);
		}
		
		ClientPrefs.colorBlindMode = switch (type) {
			case -1: 'None';
			case 0: 'Deutranopia';
			case 1: 'Protanopia';
			case 2: 'Tritanopia';
			case 3: 'Protanomaly';
			case 4: 'Deuteranomaly';
			case 5: 'Tritanomaly';
			case 6: 'Rod monochromacy';
			case 7: 'Cone monochromacy';
			default: 'None';
		};
		ClientPrefs.colorBlindIntensity = intensity;
		ClientPrefs.saveSettings();
	}

	private function pluginsLessGo()
	{
		plugins.HotReloadPlugin.init();
	}
}

#if CRASH_HANDLER
//Big thanks for NVE
class FunkinGame extends FlxGame
{
	private static function crashGame()
	{
		null
		.draw();
	}
	
	/**
	 * Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
	 */
	override function create(_):Void
	{
		try
		{
			_skipSplash = true;
			super.create(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	override function onFocus(_):Void
	{
		try
		{
			super.onFocus(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	override function onFocusLost(_):Void
	{
		try
		{
			super.onFocusLost(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	/**
	 * Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	 */
	override function onEnterFrame(_):Void
	{
		try
		{
			super.onEnterFrame(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	/**
	 * This function is called by `step()` and updates the actual game state.
	 * May be called multiple times per "frame" or draw call.
	 */
	override function update():Void
	{
		#if debug if (FlxG.keys.justPressed.F9) crashGame(); #end
		try
		{
			super.update();
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	/**
	 * Goes through the game state and draws all the game objects and special effects.
	 */
	override function draw():Void
	{
		try
		{
			super.draw();
		}
		catch (e)
		{
			onCrash(e);
		}
	}

	private final function onCrash(e:haxe.Exception):Void
    {
        Main.handleCrash(e);
    }
}
#end