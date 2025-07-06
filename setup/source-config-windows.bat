@echo off
cls
title Necessary Libraries Installer
echo.
echo Installing necessary libraries. Please wait...
echo.
haxelib setup C:\haxelib
haxelib install tjson --quiet
haxelib install hxjsonast --quiet
haxelib set flixel 5.6.2 --never --quiet
haxelib git lime https://github.com/GreenColdTea/lime-9.0.0
haxelib set openfl 9.4.1
haxelib install hxcpp --quiet
haxelib install hxvlc --quiet --skip-dependencies
haxelib run lime setup flixel
haxelib set flixel-tools 1.5.1
haxelib set flixel-ui 2.6.3
haxelib set flixel-addons 3.3.2
haxelib set hscript 2.4.0
haxelib install hxdiscord_rpc 1.2.4 --quiet
haxelib git sl-windows-api https://github.com/GreenColdTea/windows-api-improved.git
haxelib git flxanimate https://github.com/Psych-Slice/FlxAnimate.git 18091dfeb629ba2805a5f3e10f5de80433080359
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib list
echo.
echo Done! Press any key to close the app!
pause
