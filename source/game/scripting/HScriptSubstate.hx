package game.scripting;

using StringTools;
//Same as HScriptState, but for substates
class HScriptSubstate extends MusicBeatSubstate
{
	public static var instance:HScriptSubstate;
	public var data:Dynamic = null;
	
	public function new(stateName:String, ?_data:Dynamic) {
		if(_data != null) this.data = _data;

		super();
		instance = this;
		this.useCustomStateName = true;
		this.className = stateName;
	}
	
	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
