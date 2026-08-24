package mklib.math;

class MathTool
{
	public inline static function floatFix(v:Float, length:Int):Float
	{
		var ret:Float = v;

		try
		{
			var strV:String = Std.string(v);

			var decimals:Array<String> = strV.split(".");
			var digits:String = decimals[1].substr(0, length);

			ret = Std.parseFloat(decimals[0] + "." + digits);
		}
		catch (e)
		{
			ret = v;
		}

		return ret;
	}
}
