package game.backend.plugins;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.util.FlxSignal;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;

/**
 * Plugin that allows easy command line access w/o compiling
 * 
 * press F12 to open system command line
 */
class CMDEnablingPlugin extends FlxBasic
{
    static var instance:Null<CMDEnablingPlugin> = null;
    
    var console:Sprite;
    var consoleText:TextField;
    var consoleVisible:Bool = false;
    var consoleWidth:Int = 400;
    
    public static function init()
    {
        if (instance == null) FlxG.plugins.addPlugin(instance = new CMDEnablingPlugin());
    }
    
    public function new()
    {
        super();
        this.visible = false;
        createConsole();
        hijackTrace();
    }
    
    @:noCompletion
    function createConsole():Void
    {
        console = new Sprite();
        console.graphics.beginFill(0x000000, 0.7);
        console.graphics.drawRect(0, 0, FlxG.width, 200);
        console.graphics.endFill();

        console.x = FlxG.width - consoleWidth;
        
        consoleText = new TextField();
        consoleText.x = 5;
        consoleText.width = consoleWidth - 10;
        consoleText.height = 200;
        consoleText.multiline = true;
        consoleText.wordWrap = true;
        consoleText.defaultTextFormat = new TextFormat("Courier New", 13, 0xFFFFFF);
        consoleText.text = "Debug Console - Press F12 to hide/show\n\n";
        
        console.addChild(consoleText);
        console.visible = false;
        FlxG.stage.addChild(console);
    }
    
    @:noCompletion
    private function hijackTrace():Void
    {
        var originalTrace = haxe.Log.trace;
        
        haxe.Log.trace = (v:Dynamic, ?infos:haxe.PosInfos) -> {
            var message = '${infos.fileName}:${infos.lineNumber} - $v\n';
            consoleText.text += message;
            consoleText.scrollV = consoleText.maxScrollV;
            originalTrace(v, infos);
        };
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (FlxG.keys.justPressed.F12)
        {
            consoleVisible = !consoleVisible;
            console.visible = consoleVisible;
        }
    }
}