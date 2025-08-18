package game.backend.mobile;

#if android
//import android.Hardware;
import android.Permissions;
import android.os.Environment;
import android.widget.Toast;
#elseif ios
import UIKit.UIScrollView;
import UIKit.UITextView;
import UIKit.UIAlertView;
#end
import haxe.CallStack;
import haxe.io.Path;
import haxe.io.Bytes;
import flixel.FlxG;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import lime.app.Application;
import openfl.system.System;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import openfl.utils.Assets;
import flixel.FlxState;
import flixel.addons.ui.FlxUIButton;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import sys.FileSystem;
import sys.io.Process;
import sys.io.File;

using StringTools;

/**
* @author: Sirox (all code here is stolen /j)
* @version: 1.1
* extension-androidtools by @M.A. Jigsaw
*/
class Generic {
	
	public static var mode:Modes = ROOTDATA;
	private static var path:String = null;
	public static var initState:FlxState = null;
	
	/**
	* returns some paths depending on current 'mode' variable or you can force it to any mode by typing it into ()
	*/
	public static function returnPath(m:Modes = ROOTDATA):String {
		#if android
		if (m == ROOTDATA && mode != ROOTDATA) {
			m = mode;
		}
		switch (m) {
			case ROOTDATA:
				path = lime.system.System.applicationStorageDirectory;
			case INTERNAL:
				path = Environment.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file') + '/';
				if (!FileSystem.exists(path)) {
					FileSystem.createDirectory(path);
				}
			case MEDIAFILE:
				path = Environment.getExternalStorageDirectory() + '/Android/media/' + Application.current.meta.get('packageName') + '/';
				if (!FileSystem.exists(path)) {
					FileSystem.createDirectory(path);
				}
			case OBB:
				path = Environment.getExternalStorageDirectory() + '/Android/obb/' + Application.current.meta.get('packageName') + '/';
				if (!FileSystem.exists(path)) {
					FileSystem.createDirectory(path);
				}
		}
		if (path != null && path.length > 0) {
			trace(path);
			return path;
		}
		trace('DEATH');
		return null;
		#else
		path = '';
		return path;
		#end
	}
	
	/**
	 * crash handler (it works only with exceptions thrown by haxe, for example glsl death or fatal signals wouldn't be saved using this)
         * @author: sqirra-rng
         * @edit: Saw (M.A. Jigsaw)
	 */
	public static function initCrashHandler() {
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function(e:UncaughtErrorEvent) {
            e.preventDefault();
		    e.stopPropagation();
		    e.stopImmediatePropagation();

		var m:String = e.error;
		if (Std.isOfType(e.error, Error)) {
			var err = cast(e.error, Error);
			m = '${err.message}';
		} else if (Std.isOfType(e.error, ErrorEvent)) {
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		var stack = haxe.CallStack.exceptionStack();
		var stackLabelArr:Array<String> = [];
		var stackLabel:String = "";
		for(e in stack) {
			switch(e) {
				case CFunction: stackLabelArr.push("Non-Haxe (C) Function");
				case Module(c): stackLabelArr.push('Module ${c}');
				case FilePos(parent, file, line, col):
					switch(parent) {
						case Method(cla, func):
							stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		stackLabel = stackLabelArr.join('\r\n');
		#if sys
		try
		{
			if (!FileSystem.exists(returnPath() + 'logs'))
				FileSystem.createDirectory(returnPath() + 'logs');

			File.saveContent('logs/' + 'Crash - ' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', '$m\n$stackLabel');
		}
		catch (e:haxe.Exception)
		trace('Couldn\'t save error message. (${e.message})');
		#end

		CoolUtil.showPopUp('$m\n$stackLabel', "Error!");

		#if html5
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		js.Browser.window.location.reload(true);
		#else
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		System.exit(1);
		#end
	        });
	    }
		
	
	public static function trace(thing:Dynamic, var_name:String, alert:Bool = false) {
		var dateNow:String = Date.now().toString();
		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");
		var fp:String = returnPath() + "logs/" + var_name + dateNow + ".txt";
		
		var thingToSave:String = forceToString(thing);
		
		if (alert) {
			Application.current.window.alert(thingToSave, 'FileTrace');
		}

		if (!FileSystem.exists(returnPath() + 'logs')) {
			FileSystem.createDirectory(returnPath() + 'logs');
		}
		
		/*if (FileSystem.exists(fp)) {
			for (i in 0.0...Math.POSITIVE_INFINITY) {
				fp = fp + i;
				if (FileSystem.exists(fp)) {
					fp = fp.replace(i, '');
				} else {
					break;
				}
			}
		}*/
		File.saveContent(fp, var_name + " = " + thingToSave + "\n");
	}
	
	public static function forceToString(shit:Dynamic):String {
		var result:String = '';
		if (!Std.isOfType(shit, String)) {
			result = Std.string(shit);
		} else {
			result = shit;
		}
		return result;
	}
	
	public static function match(val1:Dynamic, val2:Dynamic) {
		return Std.isOfType(val1, val2);
	}
	
	public static function copyContent(copyPath:String, savePath:String)
	{
	    trace(returnPath());
            trace('saving dir: ' + returnPath() + savePath);
            trace(copyPath);

            var fileName:String = returnPath() + savePath;
            trace(fileName);
            trace('FileSystem.exists(fileName) = ' + FileSystem.exists(fileName));
            trace('Assets.exists(copyPath) = ' + Assets.exists(copyPath));

            if (!FileSystem.exists(returnPath() + savePath)) {
                if (!FileSystem.exists(returnPath())) {
                    FileSystem.createDirectory(returnPath());
                }

                var fileData:Bytes;

                if (copyPath.indexOf(".mp4") > -1) {
                    fileData = Assets.getBytes('videos:' + copyPath);
                } else if (copyPath.indexOf(".lua") > -1 || copyPath.indexOf(".txt") > -1 || copyPath.indexOf(".json") > -1) {
		    fileData = haxe.io.Bytes.ofString(Assets.getText('weeks:' + copyPath));
                    fileData = haxe.io.Bytes.ofString(Assets.getText('scripts:' + copyPath));
                } else {
                    fileData = Assets.getBytes(copyPath);
                }

                if (fileData != null) {
                    File.saveBytes(fileName, fileData);
                    trace('saved');
                }
            }
	}
}

enum Modes {
	ROOTDATA;
	INTERNAL;
	MEDIAFILE;
	OBB;
}
