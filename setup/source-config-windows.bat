@echo off
cls
title Necessary Libraries Installer
echo.
echo Installing necessary libraries. Please wait...
echo.
haxelib setup C:\haxelib
haxelib install tjson --quiet
haxelib install hxjsonast --quiet
haxelib install flxgif --quiet
haxelib set flixel 6.1.0
haxelib git lime https://github.com/GreenColdTea/lime-9.0.0
haxelib install format
haxelib install hxp
haxelib set openfl 9.4.1
haxelib install hxvlc --quiet --skip-dependencies
haxelib run lime setup flixel
haxelib set flixel-tools 1.5.1
haxelib set flixel-addons 3.3.2
haxelib set hxdiscord_rpc 1.2.4
haxelib git hxcpp https://github.com/FunkinCrew/hxcpp
haxelib git flxsoundfilters https://github.com/TheZoroForce240/FlxSoundFilters.git
haxelib git rulescript https://github.com/Kriptel/RuleScript.git dev
haxelib git hscript https://github.com/HaxeFoundation/hscript.git
haxelib git sl-windows-api https://github.com/GreenColdTea/windows-api-improved.git
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate.git 40ea31d4b598a01411c8c96f52702e090478ba1f
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git
haxelib list
echo.
echo Done! Press any key to close the app!
pause
