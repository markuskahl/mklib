package mklib.light;

import flixel.FlxObject;
import flixel.util.FlxColor;

/**
 * Gerichtete Scheinwerfer-Lichtquelle (Spotlight / Taschenlampe / Lichtkegel).
 *
 * Unterstützt einen Abstrahlwinkel (`angle`), einen Gesamtkegel-Öffnungswinkel (`spotAngle`)
 * sowie einen inneren Fokuswinkel (`innerAngle`) für weiche, naturgetreue Randübergänge.
 */
class SpotLight extends Light {
	/**
	 * Die Abstrahlrichtung in Grad (0° = nach rechts, 90° = nach unten, 180° = nach links, 270° = nach oben).
	 */
	public var angle:Float = 0.0;

	/**
	 * Der gesamte Öffnungswinkel des Lichtkegels in Grad (z. B. 45°).
	 */
	public var spotAngle:Float = 45.0;

	/**
	 * Der innere Fokuswinkel in Grad, innerhalb dessen der Strahl maximale Helligkeit besitzt.
	 */
	public var innerAngle:Float = 15.0;

	/**
	 * Erstellt einen neuen gerichteten Scheinwerfer.
	 *
	 * @param x X-Koordinate in Weltpixeln.
	 * @param y Y-Koordinate in Weltpixeln.
	 * @param radius Reichweite des Scheinwerferstrahls in Pixeln (Standard: 150).
	 * @param angle Abstrahlrichtung in Grad (Standard: 0°).
	 * @param spotAngle Gesamtöffnungswinkel in Grad (Standard: 45°).
	 * @param color Farbe des Lichts (Standard: Weiß `0xFFFFFFFF`).
	 * @param intensity Helligkeit / Intensität (Standard: 1.0).
	 * @param innerAngle Innerer Fokuswinkel in Grad (Standard: 15°).
	 * @param falloff Dämpfungsexponent (Standard: 1.0).
	 */
	public function new(x:Float = 0, y:Float = 0, radius:Float = 150, angle:Float = 0, spotAngle:Float = 45, color:FlxColor = FlxColor.WHITE, intensity:Float = 1.0, innerAngle:Float = 15, falloff:Float = 1.0) {
		super(x, y, radius, color, intensity, falloff);
		this.angle = angle;
		this.spotAngle = spotAngle;
		this.innerAngle = innerAngle;
		this.lightType = SPOT;
	}

	/**
	 * Richtet den Scheinwerfer auf einen Zielpunkt in Weltkoordinaten aus.
	 *
	 * @param targetX Ziel-X-Position in Weltpixeln.
	 * @param targetY Ziel-Y-Position in Weltpixeln.
	 * @return Diese SpotLight-Instanz (Fluent Interface).
	 */
	public function pointAt(targetX:Float, targetY:Float):SpotLight {
		var dx = targetX - x;
		var dy = targetY - y;
		angle = Math.atan2(dy, dx) * (180.0 / Math.PI);
		return this;
	}

	/**
	 * Richtet den Scheinwerfer auf das Zentrum eines Spielobjekts aus.
	 *
	 * @param target Das Zielobjekt.
	 * @return Diese SpotLight-Instanz (Fluent Interface).
	 */
	public function lookAt(target:FlxObject):SpotLight {
		if (target != null) {
			var centerX = target.x + (target.width * 0.5);
			var centerY = target.y + (target.height * 0.5);
			pointAt(centerX, centerY);
		}
		return this;
	}

	override public function getShaderSpotData():Array<Float> {
		var rad = angle * (Math.PI / 180.0);
		var dirX = Math.cos(rad);
		var dirY = Math.sin(rad);

		var outerRad = Math.max(0.1, spotAngle) * 0.5 * (Math.PI / 180.0);
		var innerRad = Math.max(0.0, Math.min(innerAngle, spotAngle)) * 0.5 * (Math.PI / 180.0);

		var cosOuter = Math.cos(outerRad);
		var cosInner = Math.cos(innerRad);

		return [dirX, dirY, cosOuter, cosInner];
	}
}
