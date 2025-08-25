package game.scripting;

import sys.io.File;
import haxe.io.Path;
import flixel.util.FlxColor;
import rulescript.*;
import rulescript.parsers.*;
import rulescript.RuleScript;
import game.scripting.HScriptClassManager.ScriptClassRef;
import haxe.ds.StringMap;

using StringTools;
using Lambda;

class FunkinRScript {
    static final PRESET_VARS:Map<String, Dynamic> = [
        // Flixel Classes
        "FlxG" => flixel.FlxG,
        "FlxSprite" => flixel.FlxSprite,
        "FlxSpriteUtil" => flixel.util.FlxSpriteUtil,
        "FlxTimer" => flixel.util.FlxTimer,
        "FlxTween" => flixel.tweens.FlxTween,
        "FlxEase" => flixel.tweens.FlxEase,
        "FlxText" => flixel.text.FlxText,

        #if VIDEOS_ALLOWED
        "FunkinVideoSprite" => game.objects.FunkinVideoSprite,
        #end

        "Paths" => game.Paths,
        "Character" => game.objects.Character,
        "CoolUtil" => game.backend.utils.CoolUtil,
        "MusicBeatState" => MusicBeatState,
        "Conductor" => game.backend.Conductor,
        "ClientPrefs" => game.backend.ClientPrefs,
        "PlayState" => game.PlayState,
        "BGSprite" => game.objects.BGSprite,
        "FunkinRScript" => FunkinRScript,
        "FunkinHScript" => FunkinHScript,
        "FunkinLua" => FunkinLua,
    ];

    public var scriptType:String = "Rule/HScript";
    public var scriptName:String;
    public var active(default, null):Bool = true;
    
    private var rule:RuleScript;
    private var parentInstance:Dynamic;
    private var callbacks:Map<String, Array<Dynamic>> = new Map();
    private var importedPackages:Map<String, Bool> = new Map();

    public static function fromFile(file:String, ?instance:Dynamic, skipCreate:Bool = false):Null<FunkinRScript> {
        return switch Path.extension(file).toLowerCase() {
            case "hx": new FunkinRScript(file, instance, skipCreate);
            case _: null;
        }
    }

    public function new(path:String, parentInstance:Dynamic = null, skipCreate:Bool = false) {
        this.parentInstance = parentInstance;
        scriptName = path;

        rule = new RuleScript(new RuleScriptInterpEx(this));
        rule.scriptName = path;
        rule.errorHandler = onError;

        try {
            var content = File.getContent(path);
            execute(content, skipCreate);
        } catch (e:haxe.Exception) {
            trace('Failed to load script $path: ${e.message}');
            active = false;
        }
    }

    function execute(code:String, skipCreate:Bool) {
        presetVariables();
        rule.tryExecute(code);
        if (!skipCreate) call("onCreate");
    }

    function presetVariables() {
        for (key => value in PRESET_VARS)
            set(key, value);
            
        if (parentInstance != null)
            set("parent", parentInstance);
            
        set("import", importPackage);
        set("importClass", importClass);
    }

    public function importPackage(packageName:String):Bool {
        if (importedPackages.exists(packageName)) return true;
        
        try {
            importedPackages.set(packageName, true);
            return true;
        } catch (e:Dynamic) {
            trace('Failed to import package: $packageName - ${e.message}');
            return false;
        }
    }

    public function importClass(className:String):Bool {
        try {
            var cl = Type.resolveClass(className);
            if (cl == null) {
                trace('Class not found: $className');
                return false;
            }
            
            var parts = className.split(".");
            var simpleName = parts[parts.length - 1];
            
            set(simpleName, cl);
            return true;
        } catch (e:Dynamic) {
            trace('Failed to import class: $className - ${e.message}');
            return false;
        }
    }

    public function resolveType(typeName:String):Dynamic {
        var cl = Type.resolveClass(typeName);
        if (cl != null) return cl;
        
        for (pkg in importedPackages.keys()) {
            cl = Type.resolveClass(pkg + "." + typeName);
            if (cl != null) return cl;
        }
        
        return null;
    }

    public function call(event:String, ?args:Array<Dynamic>):Dynamic {
        if (!active) return null;
        
        if (callbacks.exists(event)) {
            for (cb in callbacks.get(event)) {
                try {
                    Reflect.callMethod(null, cb, args != null ? args : []);
                } catch (e) {
                    @:privateAccess
                    onError(haxe.Exception.caught(e));
                }
            }
        }
        
        if (!exists(event)) return null;
        
        try {
            return Reflect.callMethod(null, get(event), args != null ? args : []);
        } catch (e) {
            @:privateAccess
            onError(haxe.Exception.caught(e));
            return null;
        }
    }

    public function exists(variable:String):Bool {
        return active && rule.variables.exists(variable);
    }

    public function get(variable:String):Dynamic {
        return exists(variable) ? rule.variables.get(variable) : null;
    }

    public function set(variable:String, value:Dynamic):Void {
        if (active) rule.variables.set(variable, value);
    }

    public function addCallback(event:String, callback:Dynamic):Void {
        if (!callbacks.exists(event))
            callbacks.set(event, []);
        callbacks.get(event).push(callback);
    }

    public function removeCallback(event:String, callback:Dynamic):Bool {
        return if (callbacks.exists(event)) {
            var arr = callbacks.get(event);
            var result = arr.remove(callback);
            if (arr.length == 0) callbacks.remove(event);
            result;
        } else false;
    }

    function onError(e:haxe.Exception):Void {
        final text = 'Error in $scriptName: ${e.details()}';
        trace(text);
        CoolUtil.hxTrace(text, FlxColor.RED);
    }

    public function stop():Void {
        if (!active) return;
        
        active = false;
        rule.variables.clear();
        callbacks.clear();
        importedPackages.clear();
        rule = null;
        parentInstance = null;
    }
}

class RuleScriptInterpEx extends RuleScriptInterp {
    public static var resolveScriptState:ResolveScriptState;
    public var ref:ScriptClassRef;
    public var funkScript:FunkinRScript;
    
    public function new(?funkScript:FunkinRScript) {
        this.funkScript = funkScript;
        super();
    }
    
    override function resolveType(path:String):Dynamic {
        var resolved = funkScript.resolveType(path);
        if (resolved != null) {
            resolveScriptState = {owner: this, mode: "resolve"};
            return resolved;
        }
        
        resolveScriptState = {owner: this, mode: "resolve"};
        return super.resolveType(path);
    }
    
    override function cnew(cl:String, args:Array<Dynamic>):Dynamic {
        resolveScriptState = {owner: this, mode: "cnew", args: args};
        return super.cnew(cl, args);
    }

    override function get(o:Dynamic, f:String):Dynamic {
        if (o == this) {
            if (this.ref != null && this.ref.staticFields.exists(f))
                return this.ref.staticFields.get(f);
        }

        if (Std.isOfType(o, ScriptClassRef)) {
            var cls:ScriptClassRef = cast o;
            if (cls.staticFields.exists(f))
                return cls.staticFields.get(f);
        }

        return super.get(o, f);
    }

    override function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
        if (o == this) {
            if (this.ref != null && this.ref.staticFields.exists(f)) {
                this.ref.staticFields.set(f, v);
                return v;
            }
        }

        if (Std.isOfType(o, ScriptClassRef)) {
            var cls:ScriptClassRef = cast o;
            if (cls.staticFields.exists(f)) {
                cls.staticFields.set(f, v);
                return v;
            }
        }

        return super.set(o, f, v);
    }
}

typedef ResolveScriptState = {
    var owner:RuleScriptInterpEx;
    var mode:String; // resolve or cnew
    var ?args:Array<Dynamic>;
}