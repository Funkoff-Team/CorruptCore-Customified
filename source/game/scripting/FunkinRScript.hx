package game.scripting;

import sys.io.File;

import haxe.ds.StringMap;
import haxe.io.Path;

import rulescript.*;
import rulescript.parsers.*;
import rulescript.RuleScript;

import rulescript.interps.RuleScriptInterp;

import game.scripting.HScriptClassManager.ScriptClassRef;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;

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

        #if flxsoundfilters
        "FlxFilteredSound" => FlxFilteredSound,
        #end

        #if flxgif
        "FlxGifSprite" => FlxGifSprite,
        "FlxGifBackdrop" => FlxGifBackdrop,
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
        "FunkinLua" => FunkinLua,

        'StringMap' => haxe.ds.StringMap,
		'IntMap' => haxe.ds.IntMap,
		'ObjectMap' => haxe.ds.ObjectMap,
    ];

    static final ABSTRACT_IMPORTS:Array<String> = [
        "flixel.util.FlxColor",
        "flixel.input.keyboard.FlxKey",
        "haxe.ds.Map",
        #if flxgif
        "flxgif.FlxGifAsset",
        #end
        "openfl.display.BlendMode"
    ];

    public var scriptType:String = "N/A"; //yeah
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

        for (get in ABSTRACT_IMPORTS)
            rulescript.types.Abstracts.resolveAbstract(get);
            
        if (parentInstance != null)
            set("parent", parentInstance);

        if (FlxG.state is PlayState)
            set("game", PlayState.instance);
        
        set("add", addObject);
        set("remove", removeObject);
        set("insert", insertObject);
        set("getObject", getObject);
        set("getAll", getAllObjects);
    }

    public function addObject(object:Dynamic, ?group:String):Bool {
        if (parentInstance == null) return false;
        
        try {
            if (group != null && Reflect.hasField(parentInstance, group)) {
                var targetGroup = Reflect.field(parentInstance, group);
                if (Std.isOfType(targetGroup, FlxTypedGroup) || Std.isOfType(targetGroup, FlxGroup)) {
                    targetGroup.add(object);
                    return true;
                }
            }
            
            if (Reflect.hasField(parentInstance, "add")) {
                Reflect.callMethod(parentInstance, Reflect.field(parentInstance, "add"), [object]);
                return true;
            }
        } catch (e:Dynamic) {
            trace('Error adding object: ${e.message}');
        }
        return false;
    }

    public function removeObject(object:Dynamic, ?group:String):Bool {
        if (parentInstance == null) return false;
        
        try {
            if (group != null && Reflect.hasField(parentInstance, group)) {
                var targetGroup = Reflect.field(parentInstance, group);
                if (Std.isOfType(targetGroup, FlxTypedGroup) || Std.isOfType(targetGroup, FlxGroup)) {
                    targetGroup.remove(object);
                    return true;
                }
            }
            
            if (Reflect.hasField(parentInstance, "remove")) {
                Reflect.callMethod(parentInstance, Reflect.field(parentInstance, "remove"), [object]);
                return true;
            }
        } catch (e:Dynamic) {
            trace('Error removing object: ${e.message}');
        }
        return false;
    }

    public function insertObject(position:Int, object:Dynamic, ?group:String):Bool {
        if (parentInstance == null) return false;
        
        try {
            if (group != null && Reflect.hasField(parentInstance, group)) {
                var targetGroup = Reflect.field(parentInstance, group);
                if (Std.isOfType(targetGroup, FlxTypedGroup)) {
                    targetGroup.insert(position, object);
                    return true;
                }
            }
        } catch (e:Dynamic) {
            trace('Error inserting object: ${e.message}');
        }
        return false;
    }

    public function getObject(index:Int, group:String):Dynamic {
        if (parentInstance == null) return null;
        
        try {
            if (Reflect.hasField(parentInstance, group)) {
                var targetGroup = Reflect.field(parentInstance, group);
                if (Std.isOfType(targetGroup, FlxTypedGroup)) {
                    return targetGroup.members[index];
                }
            }
        } catch (e:Dynamic) {
            trace('Error getting object: ${e.message}');
        }
        return null;
    }

    public function getAllObjects(group:String):Array<Dynamic> {
        if (parentInstance == null) return [];
        
        try {
            if (Reflect.hasField(parentInstance, group)) {
                var targetGroup = Reflect.field(parentInstance, group);
                if (Std.isOfType(targetGroup, FlxTypedGroup)) {
                    return targetGroup.members;
                }
            }
        } catch (e:Dynamic) {
            trace('Error getting objects: ${e.message}');
        }
        return [];
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
                } catch (e:Dynamic) {
                    @:privateAccess
                    onError(haxe.Exception.caught(e));
                }
            }
        }
        
        if (!exists(event)) return null;
        
        try {
            return Reflect.callMethod(null, get(event), args != null ? args : []);
        } catch (e:Dynamic) {
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