package options;

#if desktop
import Discord.DiscordClient;
#end
import openfl.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import openfl.Lib;

using StringTools;

class MiscSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc';
		rpcTitle = 'Misc Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Adaptive Caching',
			"If checked, it will use your GPU with RAM to cache sprites.\nTurn it on, if you have a good GPU.",
			'adaptiveCache',
			'bool',
		    false);
		addOption(option);

		var option:Option = new Option('GPU Caching',
			"The same is above but GPU only.",
			'cacheOnGPU',
			'bool',
		    false);
		addOption(option);

		var option:Option = new Option('Colorblind Mode:',
			"What type of colorblind are you?",
			'colorBlindMode',
			'string',
			'None',
			['None', 'Deutranopia', 'Protanopia', 'Tritanopia', 'Protanomaly', 'Deuteranomaly', 'Tritanomaly', 'Rod monochromacy', 'Cone monochromacy']);
		addOption(option);
		option.onChange = onChangeColorBlind;

		var option:Option = new Option('Colorblind Intensity:',
			'How intense should the colorblind filter be?',
			'colorBlindIntensity',
			'percent',
			1);
		addOption(option);
		option.onChange = onChangeColorBlind;

		super();
	}

	function onChangeColorBlind()
	{
		var index = ['Deutranopia', 'Protanopia', 'Tritanopia', 'Protanomaly', 'Deuteranomaly', 'Tritanomaly', 'Rod monochromacy', 'Cone monochromacy'].indexOf(ClientPrefs.colorBlindMode);
		Main.updateColorblindFilter(index, ClientPrefs.colorBlindIntensity);
	}
}