package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import openfl.filters.ColorMatrixFilter;

//crash handler stuff
#if CRASH_HANDLER
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
		initialState: TitleState, // initial game state
        zoom: -1, // If -1, zoom is automatically calculated to fit the window dimensions.
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPS;

	public static var colorblindMode:Int = -1;
	public static var colorblindIntensity:Float = 1.0;

	// You can pretty much ignore everything from here on - your code should go in your states.

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

		#if CRASH_HANDLER
	    CrashHandler.init();
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

		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

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

        FlxG.fixedTimestep = false;
	    FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;
        FlxG.keys.preventDefaultKeys = [TAB];

		#if desktop
		DiscordClient.prepare();
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
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
