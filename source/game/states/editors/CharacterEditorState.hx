package game.states.editors;

#if DISCORD_ALLOWED
import api.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.addons.ui.FlxUIColorSwatch;
import flixel.animation.FlxAnimation;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import haxe.Json;
import lime.system.Clipboard;

import game.objects.Character;
import game.objects.FlxUIDropDownMenuCustom;
import game.objects.HealthIcon;

using StringTools;

typedef HistoryStuff = {
    var animations:Array<AnimArray>;
    var position:Array<Float>;
    var scale:Float;
    var cameraPosition:Array<Float>;
    var healthColor:Array<Int>;
	var curAnim:Int;
}

/**
	*DEBUG MODE
 */
class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var ghostChar:Character;
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var dumbTexts:FlxTypedGroup<FlxText>;
	//var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var goToPlayState:Bool = true;

	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var grid:FlxSprite;
	var gridVisible:Bool = false;

	var copiedOffsets:Array<Int> = [0, 0];

	var undos:Array<Dynamic> = [];
	var redos:Array<Dynamic> = [];
	var maxHistorySteps:Int = 75;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;

	var lastAutoSaveTime:Float = 0;
	static inline final AUTO_SAVE_INTERVAL:Float = 60; // Auto save every 60 seconds

	override function create()
	{
		//FlxG.sound.playMusic(Paths.music('breakfast'), 0.5);
		camEditor = initFNFCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);

		grid = FlxGridOverlay.create(10, 10, FlxG.width * 4, FlxG.height * 4, true, 0x22FFFFFF, 0x55FFFFFF);
		grid.screenCenter();
		grid.visible = gridVisible;
		grid.cameras = [camEditor];

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);

		add(grid);

		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		changeBGbutton = new FlxButton(FlxG.width - 360, 25, "", function()
		{
			onPixelBG = !onPixelBG;
			reloadBGs();
		});
		changeBGbutton.cameras = [camHUD];

		loadChar(!daAnim.startsWith('bf'), false);

		healthBarBG = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('healthBar'));
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		healthBarBG.cameras = [camHUD];

		leHealthIcon = new HealthIcon(char.healthIcon, false);
		leHealthIcon.y = FlxG.height - 150;
		add(leHealthIcon);
		leHealthIcon.cameras = [camHUD];

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		var tipTextArray:Array<String> = [
			"E/Q - Zoom In/Out",
			"R - Reset Zoom",
			"JKLI - Move Camera",
			"W/S - Prev/Next Animation",
			"Space - Play Animation",
			"Arrows - Move Offset",
			"T - Reset Current Offset",
			"With Shift - Move 10x Faster",
			"G - Toggle Grid",
			"CTRL + C - Copy Offsets",
			"CTRL + V - Paste Offsets",
			"CTRL + Z - Undo",
			"CTRL + Y - Redo",
			"ESC - Exit"
		];

		for (i in 0...tipTextArray.length)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		var tabs = [
			//{name: 'Offsets', label: 'Offsets'},
			{name: 'Settings', label: 'Settings'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camHUD];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camHUD];

		UI_characterbox.resize(350, 280);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);
		add(changeBGbutton);

		FlxG.camera.zoom = 1;
		FlxG.mouse.visible = true;

		addSettingsUI();

		addCharacterUI();
		addAnimationsUI();
		UI_characterbox.selected_tab_id = 'Character';

		reloadCharacterOptions();

		super.create();
	}

	var onPixelBG:Bool = false;
	var OFFSET_X:Float = 300;
	function reloadBGs() {
		var i:Int = bgLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxSprite = bgLayer.members[i];
			if(memb != null) {
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();
		var playerXDifference = 0;
		if(char.isPlayer) playerXDifference = 670;

		if(onPixelBG) {
			var playerYDifference:Float = 0;
			if(char.isPlayer) {
				playerXDifference += 200;
				playerYDifference = 220;
			}

			var bgSky:BGSprite = new BGSprite('bgs/weeb/weebSky', OFFSET_X - (playerXDifference / 2) - 300, 0 - playerYDifference, 0.1, 0.1);
			bgLayer.add(bgSky);
			bgSky.antialiasing = false;

			var repositionShit = -200 + OFFSET_X - playerXDifference;

			var bgSchool:BGSprite = new BGSprite('bgs/weeb/weebSchool', repositionShit, -playerYDifference + 6, 0.6, 0.90);
			bgLayer.add(bgSchool);
			bgSchool.antialiasing = false;

			var bgStreet:BGSprite = new BGSprite('bgs/weeb/weebStreet', repositionShit, -playerYDifference, 0.95, 0.95);
			bgLayer.add(bgStreet);
			bgStreet.antialiasing = false;

			var widShit = Std.int(bgSky.width * 6);
			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800 - playerYDifference);
			bgTrees.frames = Paths.getPackerAtlas('bgs/weeb/weebTrees');
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			bgLayer.add(bgTrees);
			bgTrees.antialiasing = false;

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));

			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();
			changeBGbutton.text = "Regular BG";
		} else {
			var bg:BGSprite = new BGSprite('stageback', -600 + OFFSET_X - playerXDifference, -300, 0.9, 0.9);
			bgLayer.add(bg);

			var stageFront:BGSprite = new BGSprite('stagefront', -650 + OFFSET_X - playerXDifference, 500, 0.9, 0.9);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			bgLayer.add(stageFront);
			changeBGbutton.text = "Pixel BG";
		}
	}

	/*var animationInputText:FlxUIInputText;
	function addOffsetsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Offsets";

		animationInputText = new FlxUIInputText(15, 30, 100, 'idle', 8);

		var addButton:FlxButton = new FlxButton(animationInputText.x + animationInputText.width + 23, animationInputText.y - 2, "Add", function()
		{
			var theText:String = animationInputText.text;
			if(theText != '') {
				var alreadyExists:Bool = false;
				for (i in 0...animList.length) {
					if(animList[i] == theText) {
						alreadyExists = true;
						break;
					}
				}

				if(!alreadyExists) {
					char.animOffsets.set(theText, [0, 0]);
					animList.push(theText);
				}
			}
		});

		var removeButton:FlxButton = new FlxButton(animationInputText.x + animationInputText.width + 23, animationInputText.y + 20, "Remove", function()
		{
			var theText:String = animationInputText.text;
			if(theText != '') {
				for (i in 0...animList.length) {
					if(animList[i] == theText) {
						if(char.animOffsets.exists(theText)) {
							char.animOffsets.remove(theText);
						}

						animList.remove(theText);
						if(char.animation.curAnim.name == theText && animList.length > 0) {
							char.playAnim(animList[0], true);
						}
						break;
					}
				}
			}
		});

		var saveButton:FlxButton = new FlxButton(animationInputText.x, animationInputText.y + 35, "Save Offsets", function()
		{
			saveOffsets();
		});

		tab_group.add(new FlxText(10, animationInputText.y - 18, 0, 'Add/Remove Animation:'));
		tab_group.add(addButton);
		tab_group.add(removeButton);
		tab_group.add(saveButton);
		tab_group.add(animationInputText);
		UI_box.addGroup(tab_group);
	}*/

	var TemplateCharacter:String = '{
			"animations": [
				{
					"loop": false,
					"offsets": [
						0,
						0
					],
					"fps": 24,
					"anim": "idle",
					"indices": [],
					"name": "Dad idle dance"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singLEFT",
					"loop": false,
					"name": "Dad Sing Note LEFT"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singDOWN",
					"loop": false,
					"name": "Dad Sing Note DOWN"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singUP",
					"loop": false,
					"name": "Dad Sing Note UP"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singRIGHT",
					"loop": false,
					"name": "Dad Sing Note RIGHT"
				}
			],
			"no_antialiasing": false,
			"image": "characters/DADDY_DEAREST",
			"position": [
				0,
				0
			],
			"healthicon": "face",
			"flip_x": false,
			"healthbar_colors": [
				161,
				161,
				161
			],
			"camera_position": [
				0,
				0
			],
			"sing_duration": 6.1,
			"vocals_file": null,
			"scale": 1
		}';

	var charDropDown:FlxUIDropDownMenuCustom;
	function addSettingsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		var check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = daAnim.startsWith('bf');
		check_player.callback = function()
		{
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			updatePointerPos();
			reloadBGs();
			ghostChar.flipX = char.flipX;
		};

		charDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
			daAnim = characterList[Std.parseInt(character)];
			check_player.checked = daAnim.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [char, ghostChar];
			for (character in characters)
			{
				character.animOffsets.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				if(character.animationsArray[0] != null) {
					character.playAnim(character.animationsArray[0].anim, true);
				}

				character.singDuration = parsedJson.sing_duration;
				character.positionArray = parsedJson.position;
				character.cameraPosition = parsedJson.camera_position;

				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.healthIcon = parsedJson.healthicon;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.setPosition(character.positionArray[0] + OFFSET_X + 100, character.positionArray[1]);
			}

			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			updatePointerPos();
			genBoyOffsets();
			saveHistoryStuff();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(charDropDown);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
	}

	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;
	var vocalsInputText:FlxUIInputText;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;

	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;

	function addCharacterUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(char.animation.curAnim != null) {
				char.playAnim(char.animation.curAnim.name, true);
			}
		});

		var decideIconColor:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
			{
				var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
				healthColorStepperR.value = coolColor.red;
				healthColorStepperG.value = coolColor.green;
				healthColorStepperB.value = coolColor.blue;
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null);
			});

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, leHealthIcon.getCharacter(), 8);

		vocalsInputText = new FlxUIInputText(15, healthIconInputText.y + 35, 75, char.vocalsFile != null ? char.vocalsFile : '', 8);

		singDurationStepper = new FlxUINumericStepper(15, healthIconInputText.y + 75, 0.1, 4, 0, 999, 1);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		if(char.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function() {
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if(char.isPlayer) char.flipX = !char.flipX;

			ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function() {
			char.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.globalAntialiasing) {
				char.antialiasing = true;
			}
			char.noAntialiasing = noAntialiasingCheckBox.checked;
			ghostChar.antialiasing = char.antialiasing;
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});

		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, vocalsInputText.y - 18, 0, 'Vocals File Postfix:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(vocalsInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}

	var ghostDropDown:FlxUIDropDownMenuCustom;
	var animationDropDown:FlxUIDropDownMenuCustom;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	function addAnimationsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";

		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenuCustom(15, animationInputText.y - 55, null, function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			if (selectedAnimation >= 0 && selectedAnimation < char.animationsArray.length) {
				var anim:AnimArray = char.animationsArray[selectedAnimation];
				animationInputText.text = anim.anim;
				animationNameInputText.text = anim.name;
				animationLoopCheckBox.checked = anim.loop;
				animationNameFramerate.value = anim.fps;
				
				if (anim.indices != null && anim.indices.length > 0) {
					animationIndicesInputText.text = anim.indices.join(",");
				} else {
					animationIndicesInputText.text = '';
				}

				curAnim = selectedAnimation;
				char.playAnim(anim.anim, true);
				
				if (ghostChar.visible) {
					ghostChar.playAnim(anim.anim, true);
				}
				
				genBoyOffsets();
			}
		});

		ghostDropDown = new FlxUIDropDownMenuCustom(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String) {
			reloadGhost();
			var selectedAnimation:Int = Std.parseInt(pressed);
			ghostChar.visible = false;
			char.alpha = 1;
			if(selectedAnimation > 0) {
				ghostChar.visible = true;
				ghostChar.playAnim(ghostChar.animationsArray[selectedAnimation-1].anim, true);
				char.alpha = 0.85;
			}
		});

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 30, "Add/Update", function() {
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if(indicesStr.length > 1) {
				for (i in 0...indicesStr.length) {
					var index:Int = Std.parseInt(indicesStr[i]);
					if(indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
						indices.push(index);
					}
				}
			}

			var lastAnim:String = '';
			if(char.animationsArray[curAnim] != null) {
				lastAnim = char.animationsArray[curAnim].anim;
			}

			var lastOffsets:Array<Int> = [0, 0];
			for (anim in char.animationsArray) {
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(char.animation.getByName(animationInputText.text) != null) {
						char.animation.remove(animationInputText.text);
					}
					char.animationsArray.remove(anim);
				}
			}

			var newAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};
			if(indices != null && indices.length > 0) {
				char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
			} else {
				char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
			}

			if(!char.animOffsets.exists(newAnim.anim)) {
				char.addOffset(newAnim.anim, 0, 0);
			}
			char.animationsArray.push(newAnim);

			if(lastAnim == animationInputText.text) {
				var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
				if(leAnim != null && leAnim.frames.length > 0) {
					char.playAnim(lastAnim, true);
				} else {
					for(i in 0...char.animationsArray.length) {
						if(char.animationsArray[i] != null) {
							leAnim = char.animation.getByName(char.animationsArray[i].anim);
							if(leAnim != null && leAnim.frames.length > 0) {
								char.playAnim(char.animationsArray[i].anim, true);
								curAnim = i;
								break;
							}
						}
					}
				}
			}

			curAnim = char.animationsArray.length - 1;
			reloadAnimationDropDown();
			char.playAnim(animationInputText.text, true);
			if (ghostChar.visible) {
				ghostChar.playAnim(animationInputText.text, true);
			}

			genBoyOffsets();
			saveHistoryStuff();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 30, "Remove", function() {
			for (anim in char.animationsArray) {
				if(animationInputText.text == anim.anim) {
					var resetAnim:Bool = false;
					if(char.animation.curAnim != null && anim.anim == char.animation.curAnim.name) resetAnim = true;

					if(char.animation.getByName(anim.anim) != null) {
						char.animation.remove(anim.anim);
					}
					if(char.animOffsets.exists(anim.anim)) {
						char.animOffsets.remove(anim.anim);
					}
					char.animationsArray.remove(anim);

					if(resetAnim && char.animationsArray.length > 0) {
                		char.playAnim(char.animationsArray[0].anim, true);
                		curAnim = 0;
						if (ghostChar.visible) {
							ghostChar.playAnim(char.animationsArray[0].anim, true);
						}
            		}

					if(resetAnim && char.animationsArray.length > 0) {
						char.playAnim(char.animationsArray[0].anim, true);
					}
					reloadAnimationDropDown();
					genBoyOffsets();
					saveHistoryStuff();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
			saveHistoryStuff();
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUINumericStepper.CHANGE_EVENT) {
        	saveHistoryStuff();
    	}
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == healthIconInputText) {
				leHealthIcon.changeIcon(healthIconInputText.text, false);
				char.healthIcon = healthIconInputText.text;
				updatePresence();
				saveHistoryStuff();
			}
			else if(sender == imageInputText) {
				char.imageFile = imageInputText.text;
				saveHistoryStuff();
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				char.jsonScale = sender.value;
				char.setGraphicSize(Std.int(char.width * char.jsonScale));
				char.updateHitbox();
				ghostChar.setGraphicSize(Std.int(ghostChar.width * char.jsonScale));
				ghostChar.updateHitbox();
				reloadGhost();
				updatePointerPos();

				if(char.animation.curAnim != null) {
					char.playAnim(char.animation.curAnim.name, true);
				}
				saveHistoryStuff();
			}
			else if(sender == positionXStepper)
			{
				char.positionArray[0] = positionXStepper.value;
				char.x = char.positionArray[0] + OFFSET_X + 100;
				updatePointerPos();
				saveHistoryStuff();
			}
			else if(sender == singDurationStepper)
			{
				char.singDuration = singDurationStepper.value;//ermm you forgot this??
				saveHistoryStuff();
			}
			else if(sender == positionYStepper)
			{
				char.positionArray[1] = positionYStepper.value;
				char.y = char.positionArray[1];
				updatePointerPos();
				saveHistoryStuff();
			}
			else if(sender == positionCameraXStepper)
			{
				char.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
				saveHistoryStuff();
			}
			else if(sender == positionCameraYStepper)
			{
				char.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
				saveHistoryStuff();
			}
			else if(sender == vocalsInputText)
			{
				char.vocalsFile = vocalsInputText.text;
			}
			else if(sender == healthColorStepperR)
			{
				char.healthColorArray[0] = Math.round(healthColorStepperR.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				saveHistoryStuff();
			}
			else if(sender == healthColorStepperG)
			{
				char.healthColorArray[1] = Math.round(healthColorStepperG.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				saveHistoryStuff();
			}
			else if(sender == healthColorStepperB)
			{
				char.healthColorArray[2] = Math.round(healthColorStepperB.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				saveHistoryStuff();
			}
		}
	}

	function reloadCharacterImage() {
		var lastAnim:String = '';
		if(char.animation.curAnim != null) {
			lastAnim = char.animation.curAnim.name;
		}
		
		// Fuck old frames
		char.frames = null;
		ghostChar.frames = null;

		char.destroyAtlas();
		char.isAnimateAtlas = false;
		char.color = FlxColor.WHITE;
		char.alpha = 1;
		
		// Animation.sex
		if(Paths.fileExists('images/' + char.imageFile + '/Animation.json', TEXT))
		{
			// animate sex loading
			char.atlas = new FlxAnimate();
			try
			{
				char.atlas.frames = Paths.getAnimateAtlas(char.imageFile);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${char.imageFile}: $e');
			}
			char.isAnimateAtlas = true;
		}
		else
		{
			// If animate sex isnt found use normal atlases
			if(Paths.fileExists('images/' + char.imageFile + '.txt', TEXT)) {
				char.frames = Paths.getPackerAtlas(char.imageFile);
			} else if(Paths.fileExists('images/' + char.imageFile + '.json', TEXT)) {
				char.frames = Paths.getAsepriteAtlas(char.imageFile);
			} else {
				char.frames = Paths.getSparrowAtlas(char.imageFile);
			}
			ghostChar.frames = char.frames;
		}

		if(char.animationsArray != null && char.animationsArray.length > 0) {
			for (anim in char.animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop;
				var animIndices:Array<Int> = anim.indices;
				
				if(char.isAnimateAtlas) {
					if(animIndices != null && animIndices.length > 0) {
						char.atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					} else {
						char.atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
					}
				} else {
					if(animIndices != null && animIndices.length > 0) {
						char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					} else {
						char.animation.addByPrefix(animAnim, animName, animFps, animLoop);
					}
				}

				if(!char.animOffsets.exists(animAnim))
					char.addOffset(animAnim, 0, 0);
			}
		} else if(!char.isAnimateAtlas) {
			char.quickAnimAdd('idle', 'BF idle dance');
		}

		// Same for ghosts
		if(ghostChar.animationsArray != null && ghostChar.animationsArray.length > 0) {
			for (anim in ghostChar.animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop;
				var animIndices:Array<Int> = anim.indices;
				
				if(ghostChar.isAnimateAtlas) {
					if(animIndices != null && animIndices.length > 0) {
						ghostChar.atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					} else {
						ghostChar.atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
					}
				} else {
					if(animIndices != null && animIndices.length > 0) {
						ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					} else {
						ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
					}
				}
			}
		} else if(!ghostChar.isAnimateAtlas) {
			ghostChar.quickAnimAdd('idle', 'BF idle dance');
		}

		if(lastAnim != '') {
			char.playAnim(lastAnim, true);
		} else {
			char.dance();
		}
		ghostDropDown.selectedLabel = '';
		reloadGhost();
	}

	function genBoyOffsets():Void
	{
		var daLoop:Int = 0;

		var i:Int = dumbTexts.members.length-1;
		while(i >= 0) {
			var memb:FlxText = dumbTexts.members[i];
			if(memb != null) {
				memb.kill();
				dumbTexts.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dumbTexts.clear();

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			text.cameras = [camHUD];

			daLoop++;
		}

		textAnim.visible = true;
		if(dumbTexts.length < 1) {
			var text:FlxText = new FlxText(10, 38, 0, "ERROR! No animations found.", 15);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			textAnim.visible = false;
		}

		 for (i in 0...dumbTexts.length) {
			var text = dumbTexts.members[i];
			if (i == curAnim) {
				text.color = FlxColor.BLUE;
				text.borderColor = FlxColor.BLACK;
				text.size = 18;
			} else {
				text.color = FlxColor.WHITE;
				text.size = 16;
			}
		}
	}

	function loadChar(isDad:Bool, blahBlahBlah:Bool = true) {
		var i:Int = charLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = charLayer.members[i];
			if(memb != null) {
				memb.kill();
				charLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();
		ghostChar = new Character(0, 0, daAnim, !isDad);
		ghostChar.debugMode = true;
		ghostChar.alpha = 0.6;
		ghostChar.visible = false;

		char = new Character(0, 0, daAnim, !isDad);
		if(char.animationsArray[0] != null) {
			char.playAnim(char.animationsArray[0].anim, true);
		}
		char.debugMode = true;

		charLayer.add(ghostChar);
		charLayer.add(char);

		char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);

		undos = [];
    	redos = [];
    	curAnim = 0;

		/* THIS FUNCTION WAS USED TO PUT THE .TXT OFFSETS INTO THE .JSON

		for (anim => offset in char.animOffsets) {
			var leAnim:AnimArray = findAnimationByName(anim);
			if(leAnim != null) {
				leAnim.offsets = [offset[0], offset[1]];
			}
		}*/

		if(blahBlahBlah) {
			genBoyOffsets();
			saveHistoryStuff();
		}
		reloadCharacterOptions();
		reloadBGs();
		updatePointerPos();
	}

	function updatePointerPos() {
		var charMidpoint = char.getMidpoint();
		var x:Float = charMidpoint.x;
		var y:Float = charMidpoint.y;
		
		if(!char.isPlayer) {
			x += 150 + char.cameraPosition[0];
		} else {
			x -= 100 + char.cameraPosition[0];
		}
		y -= 100 - char.cameraPosition[1];

		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		
		cameraFollowPointer.setPosition(x, y);
		
		/*FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x / 2;
		FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().x / 2;*/
	}

	function findAnimationByName(name:String):AnimArray {
		for (anim in char.animationsArray) {
			if(anim.anim == name) {
				return anim;
			}
		}
		return null;
	}

	function reloadCharacterOptions() {
		var ghostWasVisible:Bool = ghostChar.visible;
    	var ghostAnim:String = ghostWasVisible && ghostChar.animation.curAnim != null ? 
        	ghostChar.animation.curAnim.name : "";

		if(UI_characterbox != null) {
			imageInputText.text = char.imageFile;
			healthIconInputText.text = char.healthIcon;
			vocalsInputText.text = char.vocalsFile != null ? char.vocalsFile : '';
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text, false);
			positionXStepper.value = char.positionArray[0];
			positionYStepper.value = char.positionArray[1];
			positionCameraXStepper.value = char.cameraPosition[0];
			positionCameraYStepper.value = char.cameraPosition[1];
			reloadAnimationDropDown();
			updatePresence();
		}
	}

	function reloadAnimationDropDown() {
		var currentGhostSelection:String = ghostDropDown.selectedLabel;
		
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (i in 0...char.animationsArray.length) {
			anims.push(char.animationsArray[i].anim);
			ghostAnims.push(char.animationsArray[i].anim);
		}

		ghostDropDown.selectedId = "0";
		
		// prevents from crash
		if(anims.length < 1) {
			anims.push('NO ANIMATIONS');
			ghostAnims.push('NO ANIMATIONS');
		}
		
		animationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(anims, true));
		ghostDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(ghostAnims, true));
		
		if (currentGhostSelection != null && ghostAnims.contains(currentGhostSelection)) {
			var index = ghostAnims.indexOf(currentGhostSelection);
			ghostDropDown.selectedId = Std.string(index);
		}
		
		if (curAnim >= 0 && curAnim < anims.length) {
        	animationDropDown.selectedId = Std.string(curAnim);
    	}
		
		reloadGhost();
		
		if (curAnim >= 0 && curAnim < char.animationsArray.length) {
			var anim = char.animationsArray[curAnim];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;
			
			if (anim.indices != null && anim.indices.length > 0) {
				animationIndicesInputText.text = anim.indices.join(",");
			} else {
				animationIndicesInputText.text = '';
			}
		}
	}

	function reloadGhost() {
		var wasVisible:Bool = ghostChar.visible;
		var wasAnim:String = (ghostChar.animation.curAnim != null) ? 
			ghostChar.animation.curAnim.name : "";
		
		ghostChar.animation.destroyAnimations();
		
		ghostChar.frames = char.frames;
		for (anim in char.animationsArray) {
			var animAnim:String = anim.anim;
			var animName:String = anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = anim.loop;
			var animIndices:Array<Int> = anim.indices;
			
			if(animIndices != null && animIndices.length > 0) {
				ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			} else {
				ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}

			if(anim.offsets != null && anim.offsets.length > 1) {
				ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}

		ghostChar.visible = (ghostDropDown.selectedLabel != null && ghostDropDown.selectedLabel != '');
		char.alpha = ghostChar.visible ? 0.85 : 1;
		
		if(ghostChar.visible && wasAnim != "" && ghostChar.animation.getByName(wasAnim) != null) {
			ghostChar.playAnim(wasAnim, true);
		}
		
		if(ghostDropDown.selectedLabel == '') {
			ghostChar.visible = false;
			char.alpha = 1;
		}
		
		ghostChar.color = 0xFF666688;
		ghostChar.antialiasing = char.antialiasing;
	}

	function reloadCharacterDropDown() {
		var charsLoaded:Map<String, Bool> = new Map();

		#if sys
		characterList = [];
		var directories:Array<String> = [#if MODS_ALLOWED Paths.mods('characters/'), Paths.mods(Paths.currentModDirectory + '/characters/'), #end Paths.getPreloadPath('characters/')];
		#if MODS_ALLOWED
		for(mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/characters/'));
		#end
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						try {
							var charToCheck:String = file.substr(0, file.length - 5);
							var rawJson:String = sys.io.File.getContent(path);
							if(rawJson != null && rawJson.length > 0 && !charsLoaded.exists(charToCheck)) {
								var json = haxe.Json.parse(rawJson);
								if(json != null && Reflect.hasField(json, "animations") && Reflect.hasField(json, "image")) {
									characterList.push(charToCheck);
									charsLoaded.set(charToCheck, true);
								}
							}
						} catch(e) {
							trace('Error parsing character file: $path');
						}
					}
				}
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

		charDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}

	function resetHealthBarColor() {
		healthColorStepperR.value = char.healthColorArray[0];
		healthColorStepperG.value = char.healthColorArray[1];
		healthColorStepperB.value = char.healthColorArray[2];
		healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
	}

	function updatePresence() {
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		lastAutoSaveTime += elapsed;
		if(lastAutoSaveTime >= AUTO_SAVE_INTERVAL) {
			lastAutoSaveTime = 0;
			saveBackup();
		}

		if(char.animationsArray[curAnim] != null) {
			textAnim.text = char.animationsArray[curAnim].anim;

			var animName = char.animationsArray[curAnim].anim;
			var validAnim = false;
			
			if(char.isAnimateAtlas) {
				validAnim = char.atlas.anim.getByName(animName) != null;
			} else {
				var anim = char.animation.getByName(animName);
				validAnim = anim != null && anim.frames.length > 0;
			}
			
			if(!validAnim) {
				textAnim.text += ' (ERROR!)';
			}
		} else {
			textAnim.text = '';
		}

		if(animationInputText.hasFocus || animationNameInputText.hasFocus || animationIndicesInputText.hasFocus || imageInputText.hasFocus || healthIconInputText.hasFocus || vocalsInputText.hasFocus)
		{
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		if (FlxG.keys.justPressed.G) {
    		gridVisible = !gridVisible;
    		grid.visible = gridVisible;
		}

		var changedOffset = false;
		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.C) {
				copiedOffsets = char.animationsArray[curAnim].offsets.copy();
				changedOffset = true;
				FlxG.log.add("Offsets copied!");
			}

			if (FlxG.keys.justPressed.V) {
				char.animationsArray[curAnim].offsets = copiedOffsets.copy();
				char.addOffset(char.animationsArray[curAnim].anim, copiedOffsets[0], copiedOffsets[1]);
				ghostChar.addOffset(char.animationsArray[curAnim].anim, copiedOffsets[0], copiedOffsets[1]);
				char.playAnim(char.animationsArray[curAnim].anim, false);
				genBoyOffsets();
				saveHistoryStuff();
				changedOffset = true;
				FlxG.log.add("Offsets pasted!");
			}

			if (FlxG.keys.justPressed.Z) {
				undo();
			}

			if (FlxG.keys.justPressed.Y) {
				redo();
			}
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			if(goToPlayState) {
				FlxG.switchState(() -> new PlayState());
			} else {
				FlxG.switchState(() -> new game.states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
			FlxG.mouse.visible = false;
			return;
		}

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		if(char.animationsArray.length > 0) {
			if (FlxG.keys.justPressed.W)
			{
				curAnim -= 1;
			}

			if (FlxG.keys.justPressed.S)
			{
				curAnim += 1;
			}

			if (curAnim < 0)
				curAnim = char.animationsArray.length - 1;

			if (curAnim >= char.animationsArray.length)
				curAnim = 0;

			if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
			{
				char.playAnim(char.animationsArray[curAnim].anim, true);
				genBoyOffsets();
			}
			if (FlxG.keys.justPressed.T) {
				var originalOffsets = char.animationsArray[curAnim].offsets.copy();
					
				char.animationsArray[curAnim].offsets = [0, 0];
				char.addOffset(char.animationsArray[curAnim].anim, 0, 0);
				ghostChar.addOffset(char.animationsArray[curAnim].anim, 0, 0);
					
				char.playAnim(char.animationsArray[curAnim].anim, false);
				ghostChar.playAnim(char.animationsArray[curAnim].anim, false);
					
				genBoyOffsets();
				saveHistoryStuff();
					
				char.animationsArray[curAnim].offsets = originalOffsets;

				changedOffset = true;
			}

			var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
			var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
			if(moveKeysP.contains(true))
			{
				char.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
				char.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
				changedOffset = true;
			}

			if(moveKeys.contains(true))
			{
				holdingArrowsTime += elapsed;
				if(holdingArrowsTime > 0.6)
				{
					holdingArrowsElapsed += elapsed;
					while(holdingArrowsElapsed > (1/60))
					{
						char.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
						char.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
						holdingArrowsElapsed -= (1/60);
						changedOffset = true;
					}
				}
			}
			else holdingArrowsTime = 0;

			if (changedOffset) {
				if (char.animation.curAnim != null) {
					var animName = char.animation.curAnim.name;
					char.animOffsets.set(animName, [char.offset.x, char.offset.y]);
					
					for (anim in char.animationsArray) {
						if (anim.anim == animName) {
							anim.offsets = [Std.int(char.offset.x), Std.int(char.offset.y)];
							break;
						}
					}
					
					if (ghostChar.visible && ghostChar.animation.curAnim != null && ghostChar.animation.curAnim.name == animName) {
						ghostChar.animOffsets.set(animName, [char.offset.x, char.offset.y]);
						ghostChar.offset.set(char.offset.x, char.offset.y);
					}
					
					genBoyOffsets();
					saveHistoryStuff();
				}
				changedOffset = false;
			}
		}
		//camHUD.zoom = FlxG.camera.zoom;
		ghostChar.setPosition(char.x, char.y);
	}

	var _file:FileReference;
	/*private function saveOffsets()
	{
		var data:String = '';
		for (anim => offsets in char.animOffsets) {
			data += anim + ' ' + offsets[0] + ' ' + offsets[1] + '\n';
		}

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daAnim + "Offsets.txt");
		}
	}*/

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	* Called if there is an error while saving the gameplay recording.
	*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveBackup() {
		try {
			var backupDir = 'assets/characters/backups/';
			if (!sys.FileSystem.exists(backupDir)) {
				sys.FileSystem.createDirectory(backupDir);
			}

			var json = {
				"animations": char.animationsArray,
				"image": char.imageFile,
				"scale": char.jsonScale,
				"sing_duration": char.singDuration,
				"healthicon": char.healthIcon,
				"position":	char.positionArray,
				"camera_position": char.cameraPosition,
				"flip_x": char.originalFlipX,
				"no_antialiasing": char.noAntialiasing,
				"vocals_file": char.vocalsFile,
				"healthbar_colors": char.healthColorArray
			};

			var data:String = Json.stringify(json, "\t");
			sys.io.File.saveContent(backupDir + daAnim + '_backup.json', data);
		} catch(e) {
			trace('Failed to create backup: ' + e.message);
		}
	}

	function saveCharacter() {
		try {
			var json = {
				"animations": char.animationsArray,
				"image": char.imageFile,
				"scale": char.jsonScale,
				"sing_duration": char.singDuration,
				"healthicon": char.healthIcon,

				"position":	char.positionArray,
				"camera_position": char.cameraPosition,

				"flip_x": char.originalFlipX,
				"no_antialiasing": char.noAntialiasing,
				"vocals_file": char.vocalsFile,
				"healthbar_colors": char.healthColorArray
			};

			var data:String = Json.stringify(json, "\t");

			if (data.length > 0)
			{
				if (_file != null) {
					_file.removeEventListener(Event.COMPLETE, onSaveComplete);
					_file.removeEventListener(Event.CANCEL, onSaveCancel);
					_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
					_file = null;
				}
				
				_file = new FileReference();
				_file.addEventListener(Event.COMPLETE, onSaveComplete);
				_file.addEventListener(Event.CANCEL, onSaveCancel);
				_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
				_file.save(data, daAnim + ".json");
			}
		} catch(e) {
			trace('Failed to save character: ' + e.message);
		}
	}

	function ClipboardAdd(prefix:String = ''):String {
		if(prefix.toLowerCase().endsWith('v')) //probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length-1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}

	function saveHistoryStuff() {
		var state:HistoryStuff = {
			animations: [for (anim in char.animationsArray) {
				anim: anim.anim,
				name: anim.name,
				fps: anim.fps,
				loop: anim.loop,
				indices: anim.indices.copy(),
				offsets: anim.offsets.copy()
			}],
			position: char.positionArray.copy(),
			scale: char.jsonScale,
			cameraPosition: char.cameraPosition.copy(),
			healthColor: char.healthColorArray.copy(),
			curAnim: curAnim
		};
		
		undos.push(state);
		if (undos.length > maxHistorySteps) undos.shift();
		
		redos = [];
	}

	function undo() {
		if (undos.length == 0) return;
		
		redos.push(getCurrentState());
		restoreState(undos.pop());
		
		reloadCharacterOptions();
		genBoyOffsets();
	}

	function redo() {
		if (redos.length == 0) return;
		
		undos.push(getCurrentState());
		restoreState(redos.pop());
		
		reloadCharacterOptions();
		genBoyOffsets();
	}

	function getCurrentState():HistoryStuff {
		return {
			animations: [for (anim in char.animationsArray) {
				anim: anim.anim,
				name: anim.name,
				fps: anim.fps,
				loop: anim.loop,
				indices: anim.indices.copy(),
				offsets: anim.offsets.copy()
			}],
			position: char.positionArray.copy(),
			scale: char.jsonScale,
			cameraPosition: char.cameraPosition.copy(),
			healthColor: char.healthColorArray.copy(),
			curAnim: curAnim
		};
	}

	function restoreState(state:HistoryStuff) {
		// Recovering the anims
		char.animationsArray = [for (anim in state.animations) anim];
		ghostChar.animationsArray = [for (anim in state.animations) anim];

		for (anim in char.animationsArray) {
        	char.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
        	ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
    	}
		
		char.positionArray = state.position.copy();
		char.cameraPosition = state.cameraPosition.copy();
		char.jsonScale = state.scale;
		char.healthColorArray = state.healthColor.copy();

		if (char.animationsArray.length > 0) {
			char.playAnim(char.animationsArray[curAnim].anim, true);
			if (ghostChar.visible) {
            	ghostChar.playAnim(char.animationsArray[curAnim].anim, true);
        	}
		}

		curAnim = state.curAnim;
		if (curAnim < 0) curAnim = 0;
		if (curAnim >= char.animationsArray.length) curAnim = char.animationsArray.length - 1;
		
		reloadAnimationDropDown();
		reloadGhost();
		reloadCharacterOptions();
		reloadCharacterImage();
		updatePointerPos();
		genBoyOffsets();

		char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);
    	ghostChar.setPosition(char.x, char.y);
		
		// update health bar color
		healthBarBG.color = FlxColor.fromRGB(
			char.healthColorArray[0],
			char.healthColorArray[1],
			char.healthColorArray[2]
		);
	}

	override function destroy() {
		super.destroy();
	}
}
