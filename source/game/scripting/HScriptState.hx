package game.scripting;

#if sys
import sys.FileSystem;
#end

import openfl.utils.Assets as OpenFlAssets;

class HScriptState extends MusicBeatState
{
    public var originalClassName:String = "";
    public var stateName:String = "";
    
    public function new(className:String){
        this.originalClassName = className;
        
        var parts = className.split(".");
        this.stateName = parts[parts.length - 1];

        if (stateName != null)
            menuScriptArray.push(new FunkinHScript(stateName, this));

        super();
    }
}