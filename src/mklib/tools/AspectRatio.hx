package mklib.tools;

import openfl.system.Capabilities;
import mklib.math.MathTool;

/**
 * Werkzeug zur dynamischen Berechnung der Spielauflösung anhand des Bildschirms-Seitenverhältnisses.
 *
 * Passt die Design-Breite bei einer festen Design-Höhe (z. B. 180 Pixel) an Breitbild-Displays an,
 * sofern sich das Seitenverhältnis im unterstützten Bereich (16:9 bis ~20:9, d. h. 1.77 bis 2.22) befindet.
 */
class AspectRatio
{
	/**
	 * Das tatsächliche Seitenverhältnis des Bildschirms (`screenWidth / screenHeight`).
	 */
	private var screenRatio:Float;

	/**
	 * Die berechnete Spielbreite in Pixeln.
	 */
	public var width:Int;

	/**
	 * Die berechnete Spielhöhe in Pixeln.
	 */
	public var height:Int;

	/**
	 * Gibt an, ob die Standard-Fallback-Dimensionen (`400x180`) verwendet werden,
	 * falls das Seitenverhältnis außerhalb des tolerierten Bereichs liegt.
	 */
	public var isDefault:Bool = false;

	/**
	 * Erstellt eine neue `AspectRatio`-Instanz und berechnet die optimalen Dimensionen.
	 *
	 * Werden keine Dimensionen übergeben, wird die aktuelle Bildschirmauflösung via `Capabilities` ermittelt.
	 *
	 * @param screenWidth Optionale Bildschirmbreite in Pixeln.
	 * @param screenHeight Optionale Bildschirmhöhe in Pixeln.
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

	/**
	 * Führt die interne Berechnung von `width` und `height` auf Basis des Seitenverhältnisses durch.
	 */
	private function calc():Void
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

	/**
	 * Prüft, ob das Seitenverhältnis im unterstützten Breitbildbereich liegt (zwischen 1.77 und 2.22).
	 *
	 * @return `true`, wenn das Seitenverhältnis unterstützt wird, sonst `false`.
	 */
	public function isInRange():Bool
	{
		var ratio:Float = MathTool.floatFix(screenRatio, 2);
		return (ratio >= 1.77 && ratio <= 2.22);
	}
}
