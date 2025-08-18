package game.backend.mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import game.backend.mobile.flixel.FlxButton;
import game.backend.mobile.flixel.FlxHitbox;
import game.backend.mobile.flixel.FlxVirtualPad;
import openfl.utils.Assets;

class MobileControlsSubState extends FlxSubState
{
	private final controlsItems:Array<String> = ['Hitbox', 'Pad-Left', 'Pad-Right', 'Pad-Custom', 'Pad-Duo', 'Keyboard'];

	private var _virtualpad:FlxVirtualPad;
	private var hitbox:FlxHitbox;
	private var upPosition:FlxText;
	private var downPosition:FlxText;
	private var leftPosition:FlxText;
	private var rightPosition:FlxText;
	private var grpControls:FlxText;
	private var funitext:FlxText;
	private var leftArrow:FlxSprite;
	private var rightArrow:FlxSprite;
	private var curSelected:Int = 0;
	private var buttonBinded:Bool = false;
	private var bindButton:FlxButton;
	private var resetButton:FlxButton;
	private var StyleButton:FlxButton;

	override function create()
	{
		for (i in 0...controlsItems.length)
			if (controlsItems[i] == MobileControls.mode)
				curSelected = i;

		var bg:FlxSprite = new FlxSprite(0, 0);
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.alpha = 0.8;
		bg.scrollFactor.set();
		add(bg);

		var exitButton:FlxButton = new FlxButton(FlxG.width - 200, 50, 'Exit', function()
		{
			MobileControls.mode = controlsItems[Math.floor(curSelected)];

			if (controlsItems[Math.floor(curSelected)] == 'Pad-Custom')
				MobileControls.customVirtualPad = _virtualpad;
				
			if (controlsItems[Math.floor(curSelected)] != 'Hitbox' || controlsItems[Math.floor(curSelected)] != 'Keyboard' ){
			  ClientPrefs.isvpad = true;
			  ClientPrefs.saveSettings;
			}

			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		});
		exitButton.setGraphicSize(Std.int(exitButton.width) * 3);
		exitButton.label.setFormat("NiseSegaSonic", 21, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK, true);
		exitButton.color = FlxColor.LIME;
		add(exitButton);

		StyleButton = new FlxButton(exitButton.x, exitButton.y + 100, 'Style', function()
			{
				openSubState(new mobile.HitboxSettingsSubState());
			});

		StyleButton.setGraphicSize(Std.int(StyleButton.width) * 3);
		StyleButton.label.setFormat(Assets.getFont('assets/fonts/NiseSegaSonic.TTF').fontName, 21, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,
		FlxColor.BLACK, true);
		StyleButton.color = FlxColor.BLUE;
		add(StyleButton);

		resetButton = new FlxButton(exitButton.x, exitButton.y + 100, 'Reset', function()
		{
			if (controlsItems[Math.floor(curSelected)] == 'Pad-Custom' && resetButton.visible) // being sure about something
			{
				MobileControls.customVirtualPad = new FlxVirtualPad(RIGHT_FULL, NONE);
				reloadMobileControls('Pad-Custom');
			}
		});
		resetButton.setGraphicSize(Std.int(resetButton.width) * 3);
		resetButton.label.setFormat("NiseSegaSonic", 21, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK, true);
		resetButton.color = FlxColor.RED;
		resetButton.visible = false;
		add(resetButton);

		funitext = new FlxText(0, 0, 0, 'Controls not Found!', 32);
		funitext.setFormat("NiseSegaSonic", 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK, true);
		funitext.borderSize = 3;
		funitext.borderQuality = 1;
		funitext.screenCenter();
		funitext.visible = false;
		add(funitext);

		grpControls = new FlxText(0, 100, 0, '', 32);
		grpControls.setFormat("NiseSegaSonic", 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK, true);
		grpControls.borderSize = 3;
		grpControls.borderQuality = 1;
		grpControls.screenCenter(X);
		add(grpControls);

		leftArrow = new FlxSprite(grpControls.x - 60, grpControls.y - 25);
		leftArrow.frames = FlxAtlasFrames.fromSparrow(Assets.getBitmapData('assets/mobile/menu/arrows.png'), Assets.getText('assets/mobile/menu/arrows.xml'));
		leftArrow.animation.addByPrefix('idle', 'arrow left');
		leftArrow.animation.play('idle');
		add(leftArrow);

		rightArrow = new FlxSprite(grpControls.x + grpControls.width + 10, grpControls.y - 25);
		rightArrow.frames = FlxAtlasFrames.fromSparrow(Assets.getBitmapData('assets/mobile/menu/arrows.png'), Assets.getText('assets/mobile/menu/arrows.xml'));
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.play('idle');
		add(rightArrow);

		rightPosition = new FlxText(10, FlxG.height - 24, 0, '', 16);
		rightPosition.setFormat("NiseSegaSonic", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK, true);
		rightPosition.borderSize = 3;
		rightPosition.borderQuality = 1;
		add(rightPosition);

		leftPosition = new FlxText(10, FlxG.height - 44, 0, '', 16);
		leftPosition.setFormat("NiseSegaSonic", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK, true);
		leftPosition.borderSize = 3;
		leftPosition.borderQuality = 1;
		add(leftPosition);

		downPosition = new FlxText(10, FlxG.height - 64, 0, '', 16);
		downPosition.setFormat("NiseSegaSonic", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK, true);
		downPosition.borderSize = 3;
		downPosition.borderQuality = 1;
		add(downPosition);

		upPosition = new FlxText(10, FlxG.height - 84, 0, '', 16);
		upPosition.setFormat("NiseSegaSonic", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK, true);
		upPosition.borderSize = 3;
		upPosition.borderQuality = 1;
		add(upPosition);

		changeSelection();

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (touch in FlxG.touches.list)
		{
			if (touch.overlaps(leftArrow) && touch.justPressed)
				changeSelection(-1);
			else if (touch.overlaps(rightArrow) && touch.justPressed)
				changeSelection(1);

			if (controlsItems[Math.floor(curSelected)] == 'Pad-Custom')
			{
				if (buttonBinded)
				{
					if (touch.justReleased)
					{
						bindButton = null;
						buttonBinded = false;
					}
					else 
						moveButton(touch, bindButton);
				}
				else
				{
					if (_virtualpad.buttonUp.justPressed)
						moveButton(touch, _virtualpad.buttonUp);
					else if (_virtualpad.buttonDown.justPressed)
						moveButton(touch, _virtualpad.buttonDown);
					else if (_virtualpad.buttonRight.justPressed)
						moveButton(touch, _virtualpad.buttonRight);
					else if (_virtualpad.buttonLeft.justPressed)
						moveButton(touch, _virtualpad.buttonLeft);
				}
			}
		}

		if (_virtualpad != null && controlsItems[Math.floor(curSelected)] == 'Pad-Custom')
		{
			if (_virtualpad.buttonUp != null)
				upPosition.text = 'Button Up X:' + _virtualpad.buttonUp.x + ' Y:' + _virtualpad.buttonUp.y;

			if (_virtualpad.buttonDown != null)
				downPosition.text = 'Button Down X:' + _virtualpad.buttonDown.x + ' Y:' + _virtualpad.buttonDown.y;

			if (_virtualpad.buttonLeft != null)
				leftPosition.text = 'Button Left X:' + _virtualpad.buttonLeft.x + ' Y:' + _virtualpad.buttonLeft.y;

			if (_virtualpad.buttonRight != null)
				rightPosition.text = 'Button Right X:' + _virtualpad.buttonRight.x + ' Y:' + _virtualpad.buttonRight.y;
		}
	}

	private function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = controlsItems.length - 1;
		else if (curSelected >= controlsItems.length)
			curSelected = 0;

		grpControls.text = controlsItems[Math.floor(curSelected)];
		grpControls.screenCenter(X);

		leftArrow.x = grpControls.x - 60;
		rightArrow.x = grpControls.x + grpControls.width + 10;

		var daChoice:String = controlsItems[Math.floor(curSelected)];

		reloadMobileControls(daChoice);

		funitext.visible = daChoice == 'Keyboard';
		resetButton.visible = daChoice == 'Pad-Custom';
		StyleButton.visible = daChoice == 'Hitbox';
		upPosition.visible = daChoice == 'Pad-Custom';
		downPosition.visible = daChoice == 'Pad-Custom';
		leftPosition.visible = daChoice == 'Pad-Custom';
		rightPosition.visible = daChoice == 'Pad-Custom';
	}

	private function moveButton(touch:FlxTouch, button:FlxButton):Void
	{
		bindButton = button;
		bindButton.x = touch.x - Std.int(bindButton.width / 2);
		bindButton.y = touch.y - Std.int(bindButton.height / 2);

		if (!buttonBinded)
			buttonBinded = true;
	}

	private function reloadMobileControls(daChoice:String):Void
	{
		switch (daChoice)
		{
			case 'Pad-Right':
				removeControls();
				_virtualpad = new FlxVirtualPad(RIGHT_FULL, NONE);
				add(_virtualpad);
			case 'Pad-Left':
				removeControls();
				_virtualpad = new FlxVirtualPad(LEFT_FULL, NONE);
				add(_virtualpad);
			case 'Pad-Custom':
				removeControls();
				_virtualpad = MobileControls.customVirtualPad;
				add(_virtualpad);
			case 'Pad-Duo':
				removeControls();
				_virtualpad = new FlxVirtualPad(BOTH_FULL, NONE);
				add(_virtualpad);
			case 'Hitbox':
				removeControls();
				hitbox = new FlxHitbox(DEFAULT);
				add(hitbox);
			default:
				removeControls();
		}

		if (_virtualpad != null)
			_virtualpad.visible = (daChoice != 'Hitbox' && daChoice != 'Keyboard');

		if (hitbox != null)
			hitbox.visible = (daChoice == 'Hitbox');
	}

	private function removeControls():Void
	{
		if (_virtualpad != null)
			remove(_virtualpad);

		if (hitbox != null)
			remove(hitbox);
	}
}
