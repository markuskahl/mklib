package mklib.light;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
 * Abstrakte Basisklasse für alle Lichtquellen im GPU-Shader-Lighting-System.
 *
 * Verwaltet Weltkoordinaten, Farbwerte, Intensität, Dämpfung (Falloff),
 * Sichtbarkeitsstatus sowie die automatische Verfolgung beliebiger Spielobjekte (`FlxObject`).
 */
class Light implements IFlxDestroyable {
	/**
	 * Die X-Koordinate der Lichtquelle in Weltpixeln.
	 */
	public var x:Float = 0;

	/**
	 * Die Y-Koordinate der Lichtquelle in Weltpixeln.
	 */
	public var y:Float = 0;

	/**
	 * Der Radius der Lichtquelle in Weltpixeln.
	 */
	public var radius:Float = 100;

	/**
	 * Die Farbe des abgestrahlten Lichts.
	 */
	public var color:FlxColor = FlxColor.WHITE;

	/**
	 * Die Intensität / Helligkeit der Lichtquelle (1.0 = Standard, > 1.0 = Boost / Überstrahlung).
	 */
	public var intensity:Float = 1.0;

	/**
	 * Der Dämpfungsexponent für den Helligkeitsabfall (1.0 = lineare / weiche Dämpfung).
	 */
	public var falloff:Float = 1.0;

	/**
	 * Gibt an, ob das Licht aktiv berechnet und aktualisiert wird.
	 */
	public var active:Bool = true;

	/**
	 * Gibt an, ob das Licht auf dem Bildschirm gerendert wird.
	 */
	public var visible:Bool = true;

	/**
	 * Der spezifische Licht-Typ für den GPU-Shader.
	 */
	public var lightType(default, null):LightType = POINT;

	/**
	 * Ein optionales Zielobjekt (`FlxObject` oder `EntitySprite`), dem das Licht folgt.
	 */
	public var target:Null<FlxObject> = null;

	/**
	 * Der relative Versatz zum verfolgten Zielobjekt.
	 */
	public var targetOffset:FlxPoint = FlxPoint.get();

	/**
	 * Gibt an, ob das Licht an den Mittelpunkt des Zielobjekts gebunden wird.
	 */
	public var followCenter:Bool = true;

	/**
	 * Erstellt eine neue Basis-Lichtquelle.
	 *
	 * @param x X-Koordinate in Weltpixeln.
	 * @param y Y-Koordinate in Weltpixeln.
	 * @param radius Radius des Lichts in Pixeln (Standard: 100).
	 * @param color Farbe des Lichts (Standard: Weiß `0xFFFFFFFF`).
	 * @param intensity Intensität des Lichts (Standard: 1.0).
	 * @param falloff Dämpfungsexponent (Standard: 1.0).
	 */
	public function new(x:Float = 0, y:Float = 0, radius:Float = 100, color:FlxColor = FlxColor.WHITE, intensity:Float = 1.0, falloff:Float = 1.0) {
		this.x = x;
		this.y = y;
		this.radius = radius;
		this.color = color;
		this.intensity = intensity;
		this.falloff = falloff;
	}

	/**
	 * Bindet die Lichtquelle an ein Zielobjekt (`FlxObject` oder `EntitySprite`), sodass sie diesem folgt.
	 *
	 * @param target Das zu verfolgende Objekt.
	 * @param offsetX Relativer Versatz auf der X-Achse.
	 * @param offsetY Relativer Versatz auf der Y-Achse.
	 * @param center Richtet das Licht auf das Zentrum des Zielobjekts aus (`width/2`, `height/2`).
	 * @return Diese Lichtinstanz (Fluent Interface).
	 */
	public function follow(target:FlxObject, offsetX:Float = 0, offsetY:Float = 0, center:Bool = true):Light {
		this.target = target;
		this.targetOffset.set(offsetX, offsetY);
		this.followCenter = center;
		updatePositionFromTarget();
		return this;
	}

	/**
	 * Beendet die Verfolgung eines Zielobjekts.
	 *
	 * @return Diese Lichtinstanz (Fluent Interface).
	 */
	public function stopFollowing():Light {
		this.target = null;
		return this;
	}

	/**
	 * Setzt die Weltposition der Lichtquelle.
	 *
	 * @param x Neue X-Koordinate.
	 * @param y Neue Y-Koordinate.
	 * @return Diese Lichtinstanz (Fluent Interface).
	 */
	public function setPosition(x:Float, y:Float):Light {
		this.x = x;
		this.y = y;
		return this;
	}

	/**
	 * Setzt Farbe und optionale Intensität der Lichtquelle.
	 *
	 * @param color Neue Lichtfarbe.
	 * @param intensity Optionale neue Intensität.
	 * @return Diese Lichtinstanz (Fluent Interface).
	 */
	public function setColor(color:FlxColor, ?intensity:Float):Light {
		this.color = color;
		if (intensity != null) {
			this.intensity = intensity;
		}
		return this;
	}

	/**
	 * Aktualisiert die Position der Lichtquelle anhand des Zielobjekts.
	 */
	public function updatePositionFromTarget():Void {
		if (target != null && target.exists) {
			if (followCenter) {
				x = target.x + (target.width * 0.5) + targetOffset.x;
				y = target.y + (target.height * 0.5) + targetOffset.y;
			} else {
				x = target.x + targetOffset.x;
				y = target.y + targetOffset.y;
			}
		}
	}

	/**
	 * Update-Schleife der Lichtquelle. Verfolgt Ziele und aktualisiert Animationen.
	 *
	 * @param elapsed Vergangene Zeit seit dem letzten Frame in Sekunden.
	 */
	public function update(elapsed:Float):Void {
		if (!active) {
			return;
		}

		if (target != null) {
			updatePositionFromTarget();
		}
	}

	/**
	 * Gibt die effektive X-Koordinate für das Rendern zurück (z. B. inklusive Flacker-Wobble).
	 */
	public function getRenderX():Float {
		return x;
	}

	/**
	 * Gibt die effektive Y-Koordinate für das Rendern zurück (z. B. inklusive Flacker-Wobble).
	 */
	public function getRenderY():Float {
		return y;
	}

	/**
	 * Gibt den effektiven Radius für das Rendern zurück.
	 */
	public function getRenderRadius():Float {
		return radius;
	}

	/**
	 * Gibt die effektive Intensität für das Rendern zurück.
	 */
	public function getRenderIntensity():Float {
		return intensity;
	}

	/**
	 * Gibt den zusätzlichen Parameter für den Shader zurück (z. B. innerer Radius oder Fokuswinkel).
	 */
	public function getShaderExtraParam():Float {
		return 0.0;
	}

	/**
	 * Gibt Scheinwerfer-Vektordaten für den Shader zurück: `[dirX, dirY, cosOuter, cosInner]`.
	 */
	public function getShaderSpotData():Array<Float> {
		return [0.0, 1.0, -1.0, -1.0];
	}

	/**
	 * Gibt Ressourcen frei und entfernt Referenzen.
	 */
	public function destroy():Void {
		target = null;
		if (targetOffset != null) {
			targetOffset.put();
			targetOffset = null;
		}
	}
}
