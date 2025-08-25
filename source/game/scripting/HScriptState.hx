package game.scripting;

#if sys
import sys.FileSystem;
#end

import openfl.utils.Assets as OpenFlAssets;

class HScriptState extends MusicBeatState
{
    public static var state:String = "";
    
    public function new(_state:String){
        super();
        state = _state;
        
        var scriptFiles:Array<String> = [];
        var folders:Array<String> = Paths.getStateScripts(state);
        
        for (folder in folders) {
            #if sys
            if (FileSystem.exists(folder) && FileSystem.isDirectory(folder)) {
                for (file in FileSystem.readDirectory(folder)) {
                    if (file.endsWith('.hx')) {
                        var fullPath = haxe.io.Path.join([folder, file]);
                        scriptFiles.push(fullPath);
                    }
                }
            }
            #else
            var prefix = folder.replace("_append", "");
            for (asset in OpenFlAssets.list(TEXT)) {
                if (asset.startsWith(prefix) && asset.endsWith('.hx')) {
                    scriptFiles.push(asset);
                }
            }
            #end
        }
        
        if (scriptFiles.length > 0) {
            for (path in scriptFiles) {
                menuScriptArray.push(new FunkinHScript(path, this));
                
                if (path.contains('contents/'))
                    trace('Loaded mod script: $path');
                else
                    trace('Loaded base game script: $path');
            }
        } else {
            trace('No scripts found for state: $state');
        }
    }
}