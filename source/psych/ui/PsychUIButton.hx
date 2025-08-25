package psych.ui;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

import psych.ui.PsychUIBox.UIStyleData;

import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

class PsychUIButton extends FlxSpriteGroup
{
	public static final CLICK_EVENT = 'button_click';

	public var name:String;
	public var label(default, set):String;
	public var bg:FlxSprite;
	public var text:FlxText;

	public var labelOffsets:Array<FlxPoint> = [];

	public var onChangeState:String->Void;
	public var onClick:Void->Void;
	
	public var clickStyle:UIStyleData = {
		bgColor: FlxColor.BLACK,
		textColor: FlxColor.WHITE,
		bgAlpha: 1
	};
	public var hoverStyle:UIStyleData = {
		bgColor: FlxColor.WHITE,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};
	public var normalStyle:UIStyleData = {
		bgColor: 0xFFAAAAAA,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};

	var _isHovered:Bool = false;

	inline public static var useSystemCursor:Bool = true;

	public function new(x:Float = 0, y:Float = 0, label:String = '', ?onClick:Void->Void = null, ?wid:Int = 80, ?hei:Int = 20)
	{
		super(x, y);
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(bg);
		bg.color = 0xFFAAAAAA;
		bg.alpha = 0.6;

		text = new FlxText(0, 0, 1, '');
		text.alignment = CENTER;
		add(text);
		resize(wid, hei);
		this.label = label;
		
		this.onClick = onClick;
		forceCheckNext = true;
	}

	public var isClicked:Bool = false;
	public var forceCheckNext:Bool = false;
	public var broadcastButtonEvent:Bool = true;
	var _firstFrame:Bool = true;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(_firstFrame)
		{
			bg.color = normalStyle.bgColor;
			bg.alpha = normalStyle.bgAlpha;
			text.color = normalStyle.textColor;
			_firstFrame = false;
		}
		
		if(isClicked && FlxG.mouse.released)
		{
			forceCheckNext = true;
			isClicked = false;
		}

		if(forceCheckNext || FlxG.mouse.justMoved || FlxG.mouse.justPressed)
		{
			var overlapped:Bool = (FlxG.mouse.overlaps(bg, camera));

			if (overlapped && !_isHovered)
			{
				if (useSystemCursor) 
					Mouse.cursor = MouseCursor.BUTTON;
				_isHovered = true;
			}
			else if (!overlapped && _isHovered)
			{
				if (useSystemCursor) 
					Mouse.cursor = MouseCursor.AUTO;
				_isHovered = false;
			}

			forceCheckNext = false;

			if(!isClicked)
			{
				var style:UIStyleData = (overlapped) ? hoverStyle : normalStyle;
				bg.color = style.bgColor;
				bg.alpha = style.bgAlpha;
				text.color = style.textColor;
			}

			if(overlapped && FlxG.mouse.justPressed)
			{
				isClicked = true;
				bg.color = clickStyle.bgColor;
				bg.alpha = clickStyle.bgAlpha;
				text.color = clickStyle.textColor;
				if(onClick != null) onClick();
				if(broadcastButtonEvent) PsychUIEventHandler.event(CLICK_EVENT, this);
			}
		}
	}

	inline public function resize(width:Int, height:Int)
	{
		bg.setGraphicSize(width, height);
		bg.updateHitbox();
		text.fieldWidth = width;
		text.x = bg.x;
		text.y = bg.y + height/2 - text.height/2;
	}

	function set_label(v:String)
	{
		if(text != null && text.exists) text.text = v;
		return (label = v);
	}

	override public function destroy()
	{
		if (_isHovered && useSystemCursor)
			Mouse.cursor = MouseCursor.AUTO;
		
		super.destroy();
		for (point in labelOffsets) {
			FlxDestroyUtil.put(point);
		}
		labelOffsets = null;
	}
}