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
		if (screenWidth <= 0 || screenHeight <= 0)
		{
			screenWidth = Capabilities.screenResolutionX;
			screenHeight = Capabilities.screenResolutionY;
		}

		if (screenWidth <= 0 || screenHeight <= 0)
		{
			screenWidth = 1280;
			screenHeight = 720;
		}

		screenRatio = screenWidth / screenHeight;
		calc();
	}

	private function calc()
	{
		var designWidth:Int = 400;
		var designHeight:Int = 180;

		if (isInRange())
		{
			width = Math.round(designHeight * screenRatio);
			height = designHeight;
			isDefault = false;
		}
		else
		{
			width = designWidth;
			height = designHeight;
			isDefault = true;
		}
	}

	public function isInRange():Bool
	{
		var ratio:Float = MathTool.floatFix(screenRatio, 2);
		return (ratio >= 1.77 && ratio <= 2.22);
	}
}
