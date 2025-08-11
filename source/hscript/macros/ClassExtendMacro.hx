package hscript.macros;

#if macro
import haxe.macro.Type.ClassType;
import Type.ValueType;
import haxe.macro.Expr.Function;
import haxe.macro.Expr;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Type.FieldKind;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.VarAccess;
import haxe.macro.*;

using StringTools;

// BIG TODO: make typed classes scriptable
class ClassExtendMacro {
    public static inline final FUNC_PREFIX = "_HX_SUPER__";
    public static inline final CLASS_SUFFIX = "_HSX";

    public static var unallowedMetas:Array<String> = [":bitmap", ":noCustomClass", ":generic"];

    public static var modifiedClasses:Array<String> = [];

    static final BLOCKED_PACKAGES = [
        "sys.thread",
        "away3d.tools",
        "hscript",
        "flixel.addons.ui",
        "openfl.utils",
        "openfl.net"
    ];

    public static function init() {
        #if !display
        #if CUSTOM_CLASSES
        if(Context.defined("display")) return;
        for(apply in Config.ALLOWED_CUSTOM_CLASSES) {
            //idk why addGlobalMetadata uses switchTo here lol
            Compiler.addMetadata("@:build(hscript.macros.ClassExtendMacro.build())", apply);
        }
        //Context.onAfterTyping(buildTyped);
        #end
        #end
    }

    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
        var clRef = Context.getLocalClass();
        if (clRef == null) return fields;
        var cl = clRef.get();

        if (cl.isAbstract || cl.isExtern || cl.isFinal || cl.isInterface) return fields;
        if (!cl.name.endsWith("_Impl_") && !cl.name.endsWith(CLASS_SUFFIX) && !cl.name.endsWith("_HSC")) {
            var metas = cl.meta.get();

            for(m in metas)
                if (unallowedMetas.contains(m.name))
                    return fields;

            if(cl.params.length > 0)
                return fields;

            var key = cl.module;
            var fkey = cl.module + "." + cl.name;
            
            var isBlocked = false;
            for (pkg in BLOCKED_PACKAGES) {
                if (cl.module.startsWith(pkg + ".") || cl.module == pkg) {
                    isBlocked = true;
                    break;
                }
            }
            
            if (isBlocked || 
                Config.DISALLOW_CUSTOM_CLASSES.contains(key) || 
                Config.DISALLOW_CUSTOM_CLASSES.contains(fkey) ||
                cl.module.contains("_")) 
            {
                return fields;
            }

            var superFields = [];
            if(false && cl.superClass != null) {
                var _superFields = cl.superClass.t.get().fields.get();
                _superFields = []; // Comment to enable super support, (broken)

                function convertField(field:ClassField) {
                    try {
                        var nfield = FixedTypeTools.toSimpleField(field);
                        switch ([field.kind, field.type]) {
                            case [FMethod(kind), TFun(args, ret)]:
                                if(kind == MethInline)
                                    nfield.access.push(AInline);
                                if(kind == MethDynamic)
                                    nfield.access.push(ADynamic);
                            default:
                        }

                        switch(nfield.kind) {
                            case FFun(fun):
                                if (fun.params != null && fun.params.length > 0)
                                    return null;

                                //sfun.ret = Utils.fixStdTypes(fun.ret);

                                var metas = nfield.meta;
                                var defaultValues:Map<String, Dynamic> = [];
                                var defaultEntry = null;
                                var isGeneric = false;
                                for(m in metas) {
                                    if(m.name == ":value") {
                                        defaultEntry = m;
                                        switch(m.params[0].expr) {
                                            case EObjectDecl(fields):
                                                for(fil in fields)
                                                    defaultValues[fil.field] = fil.expr;
                                            default:
                                        }
                                    }
                                    if(m.name == ":generic")
                                        isGeneric = true;
                                }
                                if(isGeneric) return null;

                                if(defaultEntry != null)
                                    metas.remove(defaultEntry);

                                for(arg in fun.args) {
                                    var opt = false;
                                    if(defaultValues.exists(arg.name)) {
                                        arg.value = defaultValues[arg.name];
                                        arg.opt = false;
                                    }

                                    arg.type = null;//Utils.fixStdTypes(arg.type);

                                    //if(arg.opt) {
                                    //    if(arg.type.getParameters()[0].name != "Null")
                                    //        arg.type = TPath({name: "Null", params: [TPType(arg.type)], pack: []});//macro {Null<Dynamic>};
                                    //}
                                }

                                trace(nfield.name);
                            default:
                        }
                        return nfield;
                    } catch(e) {
                        trace(field.name, e);
                        return null;
                    }
                }

                var didPrint = false;

                var fieldNames = [for(f in fields) f.name];

                /*for(field in _superFields) {
                    if(fieldNames.contains(field.name))
                        continue;

                    if(!field.kind.match(FMethod(_))) // only catch methods
                        continue;

                    if(field.name.startsWith("get_")) {
                        var access = FixedTypeTools.getAccess(field);
                        if(access.contains(AInline) || access.contains(AFinal) || field.isFinal)
                            continue;
                        var name = field.name;
                        superFields.push({
                            name: field.name,
                            pos: field.pos,
                            kind: FFun({
                                ret: null,
                                params: [],
                                expr: macro {
                                    return super.$name();
                                },
                                args: []
                            }),
                            access: access,
                            meta: field.meta.get(),
                        });
                        //var f = convertField(field);
                        //if(f != null)
                        //    superFields.push(f);
                        if(field.name == "get_bgColor") {
                            if(!didPrint) {
                                trace(cl.name);
                                didPrint = true;
                            }
                            trace("> " + field.name + " : " + access, field);
                        }
                    }

                }*/

                // want to get this working
                /*for(field in _superFields) {
                    if(fieldNames.contains(field.name))
                        continue;

                    if(!field.kind.match(FMethod(_))) // only catch methods
                        continue;

                    var f = convertField(field);
                    if(f != null)
                        superFields.push(f);
                }*/
                //superFields = [];
            }

            var shadowClass = macro class {

            };

            var definedFields:Array<String> = [];

            //trace(getModuleName(cl));

            var hasNew = false;

            for(_field in [fields.copy(), superFields.copy()])
            for(f in _field) {
                if (f == null)
                    continue;
                if (f.name == "new") {
                    hasNew = true;
                    switch (f.kind) {
                        case FFun(fn):
                            var constructor:Field = buildConstructor(fn.args);
                            
                            shadowClass.fields.push(constructor);
                            definedFields.push(f.name);
                        default:
                            continue;
                    }
                    continue;
                }
                if (f.name.startsWith(FUNC_PREFIX))
                    continue;
                if (f.access.contains(ADynamic) || f.access.contains(AStatic) || f.access.contains(AExtern) || f.access.contains(AInline) || f.access.contains(AFinal))
                    continue;

                if(f.name == "hget" || f.name == "hset") continue; // sorry, no overwriting the hget and hset in custom classes, yet
                if(definedFields.contains(f.name)) continue; // no duplicate fields

                for(m in f.meta)
                    if (unallowedMetas.contains(m.name))
                        continue;

                switch(f.kind) {
                    case FFun(fun):
                        if (fun == null)
                            continue;
                        if (fun.params != null && fun.params.length > 0) // TODO: Support for this maybe?
                            continue;

                        if(fun.params == null)
                            fun.params = [];

                        var overrideExpr:Expr;
                        var returns:Bool = !fun.ret.match(TPath({name: "Void"}));

                        var name = f.name;

                        var arguments = fun.args == null ? [] : [for(a in fun.args) macro $i{a.name}];

                        if (returns) {
                            overrideExpr = macro {
                                var name:String = $v{name};

                                if (__interp != null && __class__fields.contains(name)) {
                                    var v:Dynamic = null;
                                    if (Reflect.isFunction(v = __interp.variables.get(name))) {
                                        return v($a{arguments});
                                    }
                                }

                                return super.$name($a{arguments});
                            };
                        } else {
                            overrideExpr = macro {
                                var name:String = $v{name};

                                if (__interp != null && __class__fields.contains(name)) {
                                    var v:Dynamic = null;
                                    if (Reflect.isFunction(v = __interp.variables.get(name))) {
                                        v($a{arguments});
                                        return;
                                    }
                                }
                                super.$name($a{arguments});
                            };
                        }

                        var superFuncExpr:Expr = returns ? {
                            macro return super.$name($a{arguments});
                        } : {
                            macro super.$name($a{arguments});
                        };

                        var func:Function = {
                            ret: fun.ret,
                            params: fun.params.copy(),
                            expr: overrideExpr,
                            args: fun.args.copy()
                        };

                        var overrideField:Field = {
                            name: f.name,
                            access: f.access.copy(),
                            kind: FFun(func),
                            pos: Context.currentPos(),
                            doc: f.doc,
                            meta: f.meta.copy()
                        };

                        if (!overrideField.access.contains(AOverride))
                            overrideField.access.push(AOverride);

                        var superField:Field = {
                            name: '$FUNC_PREFIX${f.name}',
                            pos: Context.currentPos(),
                            kind: FFun({
                                ret: fun.ret,
                                params: fun.params.copy(),
                                expr: superFuncExpr,
                                args: fun.args.copy()
                            }),
                            access: f.access.copy()
                        };
                        if (superField.access.contains(AOverride))
                            superField.access.remove(AOverride);
                        shadowClass.fields.push(overrideField);
                        shadowClass.fields.push(superField);
                        definedFields.push(f.name);
                    default:
                        // fuck off >:(

                }
            }

            var totalFields = definedFields.length;

            if(totalFields == 0 && !hasNew) {
                //Sys.println(cl.pack.join(".") + "." + cl.name + ", " + totalFields);
                return fields;
            }

            shadowClass.kind = TDClass({
                pack: cl.pack.copy(),
                name: cl.name
            }, [
                {name: "IHScriptCustomClassBehaviour", pack: ["hscript"]}
            ], false, true, false);
            shadowClass.name = '${cl.name}$CLASS_SUFFIX';
            var imports = Context.getLocalImports().copy();
            Utils.setupMetas(shadowClass, imports);
            Utils.processImport(imports, "hscript.utils.UnsafeReflect", "UnsafeReflect");

            // Adding hscript getters and setters

            shadowClass.fields.push({
                name: "__cachedFieldSet",
                pos: Context.currentPos(),
                kind: FVar(macro: Map<String, Dynamic>),
                access: [APublic, AStatic]
            });

            shadowClass.fields.push({
                name: "__interp",
                pos: Context.currentPos(),
                kind: FVar(macro: hscript.Interp),
                access: [APublic]
            });
            /*
            shadowClass.fields.push({
                name: "__custom__variables",
                pos: Context.currentPos(),
                kind: FVar(macro: Map<String, Dynamic>),
                access: [APublic]
            });
            */
            shadowClass.fields.push({
                name: "__allowSetGet",
                pos: Context.currentPos(),
                kind: FVar(macro: Bool, macro true),
                access: [APublic]
            });

            shadowClass.fields.push({
                name: "__real_fields",
                pos: Context.currentPos(),
                kind: FVar(macro: Array<String>),
                access: [APublic]
            });

            shadowClass.fields.push({
                name: "__class__fields",
                pos: Context.currentPos(),
                kind: FVar(macro: Array<String>),
                access: [APublic]
            });

            shadowClass.fields.push({
                name: "__callGetter",
                pos: Context.currentPos(),
                kind: FFun({
                    ret: macro: Dynamic,
                    params: [],
                    expr: macro {
                        return null;
                    },
                    args: [
                        {
                            name: "name",
                            opt: false,
                            meta: [],
                            type: macro: String
                        }
                    ]
                }),
                access: [APublic]
            });

            shadowClass.fields.push({
                name: "__callSetter",
                pos: Context.currentPos(),
                kind: FFun({
                    ret: macro: Dynamic,
                    params: [],
                    expr: macro {
                        return null;
                    },
                    args: [
                        {
                            name: "name",
                            opt: false,
                            meta: [],
                            type: macro: String
                        },
                        {
                            name: "val",
                            opt: false,
                            meta: [],
                            type: macro: Dynamic
                        }
                    ]
                }),
                access: [APublic]
            });

            // Todo: make it possible to override
            if(cl.name == "FunkinShader" || cl.name == "CustomShader" || cl.name == "MultiThreadedScript") {
                Context.defineModule(cl.module, [shadowClass], imports);
                return fields;
            }

            var hasHgetInSuper = false;
            var hasHsetInSuper = false;

            if(cl.name == "CustomShader") {
                hasHgetInSuper = hasHsetInSuper = true;
            }

            // TODO: somehow check the super super class
            for(_field in [fields.copy(), superFields.copy()])
            for(f in _field) {
                if (f.name == "new")
                    continue;
                if (f.name.startsWith(FUNC_PREFIX))
                    continue;
                if (f.access.contains(ADynamic) || f.access.contains(AStatic) || f.access.contains(AExtern))
                    continue;

                switch(f.kind) {
                    case FFun(fun):
                        if (fun.params != null && fun.params.length > 0)
                            continue;

                        if(!hasHgetInSuper)
                            hasHgetInSuper = f.name == "hget";
                        if(!hasHsetInSuper)
                            hasHsetInSuper = f.name == "hset";

                        if(hasHgetInSuper && hasHsetInSuper)
                            break;
                    default:

                }
            }

            var hgetField = if(hasHgetInSuper) {
                macro {
                    if (__interp != null) {
                        if(__class__fields.contains(name)) {
                            var v:Dynamic = __interp.variables.get(name);
                            if(v != null && v is hscript.Property) 
                                return cast(v, hscript.Property).callGetter(name);
                            return v;
                        }
                        else @:privateAccess {
                            var cls:hscript.CustomClass = cast __interp.__customClass.__upperClass;
                            while(cls != null) {
                                if(cls.hasField(name)) 
                                    return cls.getField(name);
                                
                                var prev:hscript.CustomClass = cast cls.__upperClass;
                                if(prev == null)
                                    break;
                                cls = prev;
                            }
                        }
                    }

                    return super.hget(name);
                }
            } else {
                macro {
                    if (__interp != null) {
                        if(__class__fields.contains(name)) {
                            var v:Dynamic = __interp.variables.get(name);
                            if(v != null && v is hscript.Property) 
                                return cast(v, hscript.Property).callGetter(name);
                            return v;
                        }
                        else @:privateAccess {
                            var cls:hscript.CustomClass = cast __interp.__customClass.__upperClass;
                            while(cls != null) {
                                if(cls.hasField(name)) 
                                    return cls.getField(name);
                                
                                var prev:hscript.CustomClass = cast cls.__upperClass;
                                if(prev == null)
                                    break;
                                cls = prev;
                            }
                        }
                    }

                    return UnsafeReflect.getProperty(this, name);
                }
            }

            var hsetField = if(hasHsetInSuper) {
                macro {
                    if (__interp != null) {
                        if(__class__fields.contains(name)) {
                            var v:Dynamic = __interp.variables.get(name);
                            if(v != null && v is hscript.Property) 
                                return cast(v, hscript.Property).callSetter(name, val);
                            __interp.variables.set(name, val);
                            return val;
                        }
                        else @:privateAccess {
                            var cls:hscript.CustomClass = cast __interp.__customClass.__upperClass;
                            while(cls != null) {
                                if(cls.hasField(name)) 
                                    return cls.setField(name, val);
                                
                                var prev:hscript.CustomClass = cast cls.__upperClass;
                                if(prev == null)
                                    break;
                                cls = prev;
                            }
                        }
                    }
                    
                    if(__real_fields.contains(name)) {
                        UnsafeReflect.setProperty(this, name, val);
                        return UnsafeReflect.field(this, name);
                    }
                    return super.hset(name, val);
                }
            } else {
                macro {
                    if (__interp != null) {
                        if(__class__fields.contains(name)) {
                            var v:Dynamic = __interp.variables.get(name);
                            if(v != null && v is hscript.Property) 
                                return cast(v, hscript.Property).callSetter(name, val);
                            __interp.variables.set(name, val);
                            return val;
                        }
                        else @:privateAccess {
                            var cls:hscript.CustomClass = cast __interp.__customClass.__upperClass;
                            while(cls != null) {
                                if(cls.hasField(name)) 
                                    return cls.setField(name, val);
                                
                                var prev:hscript.CustomClass = cast cls.__upperClass;
                                if(prev == null)
                                    break;
                                cls = prev;
                            }
                        }
                    }

                    if(__real_fields.contains(name)) {
                        UnsafeReflect.setProperty(this, name, val);
                        return UnsafeReflect.field(this, name);
                    }
                    //__custom__variables.set(name, val);
                    return val;
                }
            }

            //if(hasHsetInSuper || hasHgetInSuper) return fields;

            //trace(cl.name);

            shadowClass.fields.push({
                name: "hset",
                pos: Context.currentPos(),
                access: hasHsetInSuper ? [AOverride, APublic] : [APublic],
                kind: FFun({
                    ret: macro: Dynamic,
                    params: [],
                    expr: hsetField,
                    args: [
                        {
                            name: "name",
                            opt: false,
                            meta: [],
                            type: macro: String
                        },
                        {
                            name: "val",
                            opt: false,
                            meta: [],
                            type: macro: Dynamic
                        }
                    ]
                })
            });

            shadowClass.fields.push({
                name: "hget",
                pos: Context.currentPos(),
                access: hasHgetInSuper ? [AOverride, APublic] : [APublic],
                kind: FFun({
                    ret: macro: Dynamic,
                    params: [],
                    expr: hgetField,
                    args: [
                        {
                            name: "name",
                            opt: false,
                            meta: [],
                            type: macro: String
                        }
                    ]
                })
            });

            /*var p = new Printer();
            var aa = p.printTypeDefinition(shadowClass);
            if(aa.length < 5024)
            trace(aa);
            if(aa.indexOf("pack") >= 0)
            if(cl.name == "FunkinShader")*/

            Context.defineModule(cl.module, [shadowClass], imports);
        }

        return fields;
    }

    static function buildConstructor(constArgs:Array<FunctionArg>):Field {
        var superCallArgs:Array<Expr> = [for (arg in constArgs) macro $i{arg.name}];

        return {
            name: 'new',
            access: [APublic],
            pos: Context.currentPos(),
            kind: FFun({
                args: constArgs,
                expr: macro {
                    // Call the super constructor with appropriate args
                    super($a{superCallArgs});

                    if(__cachedFieldSet != null) {
                        for(k => v in __cachedFieldSet) {
                            Reflect.setProperty(this, k, v);
                        }
                        __cachedFieldSet.clear();
                        __cachedFieldSet = null;
                    }
                }
            }),
        };
    }

    static function buildTyped(modules:Array<haxe.macro.Type.ModuleType>) {
        for(m in modules) {
            switch(m) {
                case TClassDecl(c):
                    var cl = c.get();
                    if (cl.isAbstract || cl.isExtern || cl.isFinal || cl.isInterface)
                        continue;
                    if (cl.params.length == 0)
                        continue;
                    if (!cl.name.endsWith("_Impl_") && !cl.name.endsWith(CLASS_SUFFIX) && !cl.name.endsWith("_HSC"))
                        buildTypedClass(cl);
                default:
            }
        }
    }

    static function buildTypedClass(cl:ClassType) {}

    static function buildShadowClass(cl:ClassType) {}
}
#else
class ClassExtendMacro {
    public var usedClass:Class<Dynamic>;
    public var className:String;
}
#end