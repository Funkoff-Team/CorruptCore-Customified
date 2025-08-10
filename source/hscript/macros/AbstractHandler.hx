package hscript.macros;

#if macro
import Type.ValueType;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Printer;
import haxe.macro.Compiler;
import haxe.macro.Type.ClassType;

using StringTools;
using Lambda;

class AbstractHandler {
    static final BLOCKED_PACKAGES = [
        "cpp",
        "openfl",
        "flixel",
        "lime",
        "haxe.ds",
        "haxe.display",
		"haxe.xml.Parser"
    ];

    public static function init() {
        #if !display
        if (Context.defined("display")) return;
        for (apply in Config.ALLOWED_ABSTRACT_AND_ENUM) {
            Compiler.addGlobalMetadata(apply, '@:build(hscript.macros.AbstractHandler.build())');
        }
        #end
    }

    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
        var clRef = Context.getLocalClass();
        if (clRef == null) return fields;
        var cl:ClassType = clRef.get();

        if (cl.name.endsWith("_Impl_") 
            && cl.params.length <= 0 
            && !cl.meta.has(":multiType") 
            && !cl.name.contains("_HSC")) 
        {
            var trimEnum = cl.name.substr(0, cl.name.length - 6);
            var key = cl.module;
            var fkey = cl.module + "." + trimEnum;
            
            var isBlocked = false;
            for (pkg in BLOCKED_PACKAGES) {
                if (cl.module.startsWith(pkg + ".") || cl.module == pkg) {
                    isBlocked = true;
                    break;
                }
            }
            
            if (isBlocked || 
                cl.module.contains("_") || 
                Config.DISALLOW_ABSTRACT_AND_ENUM.contains(cl.module) || 
                Config.DISALLOW_ABSTRACT_AND_ENUM.contains(fkey))
            {
                return fields;
            }

            for (f in fields) {
                if (f.access.contains(AInline)) continue;
                
                switch (f.kind) {
                    case FFun(fun) if (f.access.contains(AStatic) && fun.expr != null):
                        fun.expr = macro @:privateAccess $e{fun.expr};
                    
                    case FVar(t, e) if (f.access.contains(AStatic) || cl.meta.has(":enum") || f.name.toUpperCase() == f.name):
                        var name = f.name;
                        var complexType = t;
                        
                        if (complexType == null && e != null) {
                            complexType = switch (e.expr) {
                                case EConst(CRegexp(_)): TPath({name: "EReg", pack: []});
                                default: null;
                            }
                        }
                        
                        var code = Context.parse('@:privateAccess ($trimEnum.$name)', f.pos);
                        f.kind = FVar(null, code);
                    
                    default:
                }
            }
        }

        return fields;
    }
}
#end