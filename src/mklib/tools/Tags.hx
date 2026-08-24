package mklib.tools;

import mklib.state.State;
import flixel.FlxG;
import nape.callbacks.CbType;

class Tags
{
	public static function get(tag:String):CbType
	{
		if (tag == null || FlxG.state == null || !Std.isOfType(FlxG.state, State))
		{
			return null;
		}
		var state:State = cast FlxG.state;
		if (state.tags == null)
		{
			return null;
		}
		return state.tags.get(tag);
	}

	public static function exist(tag:String):Bool
	{
		if (tag == null || FlxG.state == null || !Std.isOfType(FlxG.state, State))
		{
			return false;
		}
		var state:State = cast FlxG.state;
		if (state.tags == null)
		{
			return false;
		}
		return state.tags.exists(tag);
	}
}