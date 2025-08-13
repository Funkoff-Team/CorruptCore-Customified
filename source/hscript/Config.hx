package hscript;

class Config {
	// Runs support for custom classes in these
	public static final ALLOWED_CUSTOM_CLASSES = [
		"flixel",

		"game",
		#if MODCHART_ALLOWED
		"modchart.engine",
		"modchart.backend.standalone",
		#end
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"flixel",
		"openfl",

		"haxe.xml",
		"haxe.CallStack",
		"game",
	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_CUSTOM_CLASSES = [
		
	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [
		"flixel.addons.ui",
		"game.backend.Controls",
		"game.backend.utils.WindowsRegistry"
	];
}