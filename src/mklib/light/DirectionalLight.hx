package mklib.light;

import flixel.util.FlxColor;

/**
 * Globales Richtungs- und Umgebungslicht (Sonne, Mond, Tageslichtfilter).
 *
 * Beleuchtet die gesamte Szene gleichmäßig aus einem bestimmten Lichteinfallswinkel.
 */
class DirectionalLight extends Light {
	/**
	 * Der Einfallswinkel des Richtungslichts in Grad.
	 */
	public var directionAngle:Float = 45.0;

	/**
	 * Erstellt eine neue globale Richtungslichtquelle.
	 *
	 * @param directionAngle Einfallswinkel in Grad (Standard: 45°).
	 * @param color Farbe des Lichts (Standard: Warmes Sonnenweiß `0xFFFFF8EE`).
	 * @param intensity Intensität des Lichts (Standard: 0.5).
	 */
	public function new(directionAngle:Float = 45.0, color:FlxColor = 0xFFFFF8EE, intensity:Float = 0.5) {
		super(0, 0, 999999.0, color, intensity, 0.0);
		this.directionAngle = directionAngle;
		this.lightType = DIRECTIONAL;
	}

	override public function getShaderSpotData():Array<Float> {
		var rad = directionAngle * (Math.PI / 180.0);
		return [Math.cos(rad), Math.sin(rad), -1.0, -1.0];
	}
}
