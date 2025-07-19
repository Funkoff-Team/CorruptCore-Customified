#if !macro
import Paths;

//Flixel
#if (flixel >= '5.3.0')
import flixel.sound.FlxSound;
#else
import flixel.sound.FlxSound;
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
import shaders.flixel.FlxShader;

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

#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end

import states.*;
import substates.*;
import stages.*;
import math.*;

import stages.backend.BaseStage;
import flixel.animation.PsychAnimationController;

// Windows API
#if windows
import winapi.*;
#end

// that too
#if mobile
import mobile.*;
#end

import shaders.*;

#if sys
import sys.*;
import sys.io.*;
#end

using StringTools;
#end

