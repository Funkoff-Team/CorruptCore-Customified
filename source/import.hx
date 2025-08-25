#if !macro
import game.Paths;

//Flixel
#if (flixel >= '5.3.0')
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;

import lime.app.Application;

import game.shaders.flixel.FlxShader;

// Android things (will be neccesary in the future)
#if android
import android.content.Context as AndroidContext;
import android.widget.Toast as AndroidToast;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.Tools as AndroidTools;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
import android.os.BatteryManager as AndroidBatteryManager;
#end

import psych.ui.*;

#if flixel_animate
import animate.*;
import animate.FlxAnimate;
#end

//mb lol
#if haxeui_flixel
import haxe.ui.backend.flixel.UIState;
#end

import game.*;
import game.backend.*;
import game.backend.utils.*;
import game.states.*;
import game.states.options.*;
import game.substates.*;
import game.substates.options.*;
import game.stages.*;

import game.objects.Alphabet;
import game.objects.AttachedSprite;
import game.objects.CustomFadeTransition;
import game.objects.BGSprite;

import game.stages.backend.BaseStage;

import game.states.backend.MusicBeatState;
import game.substates.backend.MusicBeatSubstate;

import flixel.animation.PsychAnimationController;

// Windows API
#if (cpp && windows)
import winapi.*;
#end

// that too
#if mobile
import game.backend.mobile.*;
#end

import game.shaders.*;

#if sys
import sys.*;
import sys.io.*;
#end

using StringTools;
#end

