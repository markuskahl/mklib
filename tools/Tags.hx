package mklib.tools;

import PlayState;
import flixel.FlxG;
import nape.callbacks.CbType;

class Tags
{
	public static function get(tag:String):CbType
	{
		var state:PlayState = cast FlxG.state;
		return state.tags.get(tag);
	}

	public static function exist(tag:String):Bool
	{
		var state:PlayState = cast FlxG.state;
		return state.tags.exists(tag);
	}
}