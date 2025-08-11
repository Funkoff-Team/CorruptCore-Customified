@echo off
cls
title Necessary Libraries Installer
echo.
echo Installing necessary libraries. Please wait...
echo.
haxelib setup C:\haxelib
haxelib install tjson --quiet
haxelib install hxjsonast --quiet
haxelib set flixel 6.0.0
haxelib git lime https://github.com/GreenColdTea/lime-9.0.0
haxelib install format
haxelib install hxp
haxelib set openfl 9.4.1
haxelib install hxcpp --quiet
haxelib install hxvlc --quiet --skip-dependencies
haxelib run lime setup flixel
haxelib set flixel-tools 1.5.1
haxelib set flixel-ui 2.6.4
haxelib set flixel-addons 3.3.2
haxelib set hxdiscord_rpc 1.2.4
haxelib git hscript https://github.com/CodenameCrew/hscript-improved.git codename-dev
haxelib git sl-windows-api https://github.com/GreenColdTea/windows-api-improved.git
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate.git 8487b0f2ea771bb4aa66675101043d5eb195f3ab
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git
haxelib list
echo.
echo Done! Press any key to close the app!
pause
