package mklib.tools;

import openfl.system.Capabilities;
import mklib.math.MathTool;

class AspectRatio
{
	private var screenRatio:Float;

	public var width:Int;
	public var height:Int;
	public var isDefault:Bool = false;

	/**
	 * [Description]
	 */
	public function new(?screenWidth:Float = 0, ?screenHeight:Float = 0)
	{
		if (screenWidth == 0 && screenHeight == 0)
		{
			screenWidth = Capabilities.screenResolutionX;
			screenHeight = Capabilities.screenResolutionY;
		}

		screenRatio = screenWidth / screenHeight;
		calc();
	}

	private function calc()
	{
		if (isInRange())
		{
			var designWidth:Int = 400;
			var designHeight:Int = 180;

			var designRatio:Float = designWidth / designHeight;
			var prozentsatz:Float = Math.fround((screenRatio / designRatio) * 100);

			width = Math.round((designWidth * prozentsatz) / 100);
			height = designHeight;
		}
		else
		{
			width = 400;
			height = 180;
		}
	}

	public function isInRange():Bool
	{
		var ret:Bool = false;

		var ratio:Float = MathTool.floatFix(screenRatio, 2);

		if (ratio >= 1.77 && ratio <= 2.22)
		{
			ret = true;
		}

		return ret;
	}
}
