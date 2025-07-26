package game.scripting;

using StringTools;
//Used for custom states so you don't have to build off of the base states
class HScriptState extends MusicBeatState
{
	public static var instance:HScriptState;
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
