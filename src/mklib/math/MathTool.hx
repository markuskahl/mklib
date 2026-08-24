package mklib.math;

class MathTool
{
	public inline static function floatFix(v:Float, length:Int):Float
	{
		if (Math.isNaN(v) || !Math.isFinite(v))
		{
			return v;
		}
		var factor:Float = Math.pow(10, length);
		return Math.round(v * factor) / factor;
	}
}
