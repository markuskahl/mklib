package mklib.light;

import flixel.util.FlxColor;

/**
 * Omnidirektionale Punktlichtquelle (360° Abstrahlung).
 *
 * Unterstützt einen inneren Radius (`innerRadius`), innerhalb dessen das Licht
 * mit voller 100%iger Helligkeit scheint, bevor der sanfte Dämpfungsverlauf einsetzt.
 */
class PointLight extends Light {
	/**
	 * Der innere Radius in Pixeln, in dem das Licht ohne Helligkeitsverlust strahlt.
	 */
	public var innerRadius:Float = 0.0;

	/**
	 * Erstellt eine neue Punktlichtquelle.
	 *
	 * @param x X-Koordinate in Weltpixeln.
	 * @param y Y-Koordinate in Weltpixeln.
	 * @param radius Gesamtradius des Lichts in Pixeln (Standard: 100).
	 * @param color Farbe des Lichts (Standard: Weiß `0xFFFFFFFF`).
	 * @param intensity Helligkeit / Intensität (Standard: 1.0).
	 * @param innerRadius Innerer 100%-Helligkeitsradius in Pixeln (Standard: 0.0).
	 * @param falloff Dämpfungsexponent (Standard: 1.0).
	 */
	public function new(x:Float = 0, y:Float = 0, radius:Float = 100, color:FlxColor = FlxColor.WHITE, intensity:Float = 1.0, innerRadius:Float = 0.0, falloff:Float = 1.0) {
		super(x, y, radius, color, intensity, falloff);
		this.innerRadius = innerRadius;
		this.lightType = POINT;
	}

	override public function getShaderExtraParam():Float {
		return innerRadius;
	}
}
