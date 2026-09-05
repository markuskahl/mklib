package mklib.effect;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import mklib.effect.shader.HazardLiquidShader;

/**
 * Fertig konfiguriertes Spielobjekt (`FlxSprite`) für animierte Lava-, Säure- und Giftbecken in `mklib`.
 *
 * Rendert eine prozedurale Flüssigkeitsfläche mit GPU-beschleunigtem `HazardLiquidShader`,
 * einschließlich Strömung, aufbrechender Kruste, Hitze-Adern, Oberflächenwellen und Glühkante.
 */
class HazardLiquidPlane extends FlxSprite {
	/**
	 * Die Instanz des zugeordneten GPU-Flüssigkeits-Shaders.
	 */
	public var shaderInstance(default, null):HazardLiquidShader;

	/**
	 * Der aktuelle Flüssigkeitstyp (Lava, Säure/Slime, Giftwasser, Benutzerdefiniert).
	 */
	public var liquidType(default, set):HazardLiquidType;

	/**
	 * Schaden pro Sekunde bei Berührung durch Spielfiguren/Entities.
	 */
	public var damagePerSecond:Float = 20.0;

	/**
	 * Bestimmt, ob die Flüssigkeit Schaden zufügen soll (`true`) oder rein dekorativ ist (`false`).
	 */
	public var isHazardous:Bool = true;

	/**
	 * Bestimmt, ob der Shader automatisch in jedem Frame mit der Kamera synchronisiert wird.
	 */
	public var autoUpdateShader:Bool = true;

	/**
	 * Erstellt ein neues Lava- oder Säurebecken an den angegebenen Weltkoordinaten.
	 *
	 * @param x X-Koordinate des Beckens in Weltpixeln.
	 * @param y Y-Koordinate der Flüssigkeitsoberfläche in Weltpixeln.
	 * @param width Breite des Beckens in Pixeln.
	 * @param height Tiefe / Höhe des Beckens in Pixeln.
	 * @param type Der gewünschte Flüssigkeitstyp (Standard: `HazardLiquidType.LAVA`).
	 */
	public function new(x:Float, y:Float, width:Int, height:Int, type:HazardLiquidType = LAVA) {
		super(x, y);

		// Volle weiße Maske als Canvas für den GPU-Shader erstellen
		makeGraphic(width, height, FlxColor.WHITE, true);

		shaderInstance = new HazardLiquidShader();
		this.shader = shaderInstance;
		this.liquidType = type;

		// Unbewegliches Level-Objekt
		immovable = true;
		moves = false;
	}

	/**
	 * Aktualisiert den Shader pro Frame und synchronisiert Zeit und Weltposition.
	 */
	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (autoUpdateShader && shaderInstance != null) {
			shaderInstance.update(elapsed, x, y, width, height, camera != null ? camera : FlxG.camera);
		}
	}

	/**
	 * Ändert die Größe des Beckens und passt die interne Textur an.
	 *
	 * @param newWidth Neue Breite in Pixeln.
	 * @param newHeight Neue Höhe in Pixeln.
	 */
	public function resizePlane(newWidth:Int, newHeight:Int):Void {
		makeGraphic(newWidth, newHeight, FlxColor.WHITE, true);
	}

	/**
	 * Prüft, ob ein anderes Spielobjekt (`FlxObject` / `Entity`) in das Flüssigkeitsbecken eingetaucht ist.
	 *
	 * @param object Das zu prüfende Objekt.
	 * @return `true`, wenn sich das Objekt innerhalb der Bounding-Box des Beckens befindet.
	 */
	public function isOverlapping(object:FlxObject):Bool {
		if (object == null || !object.exists || !object.alive)
			return false;

		return (object.x + object.width > x && object.x < x + width && object.y + object.height > y && object.y < y + height);
	}

	/**
	 * Wendet fortlaufenden Umgebungsschaden auf ein berührendes `FlxSprite` (z. B. `Hero`, `EntitySprite`) an, falls `isHazardous = true`.
	 * Ruft standardmäßig `sprite.hurt(damage)` auf oder leitet den Schaden an `onCustomDamage` weiter.
	 *
	 * @param sprite Das berührende Sprite mit Health-System (`FlxSprite`, `EntitySprite`, `EntityNapeSprite`).
	 * @param elapsed Vergangene Frame-Zeit in Sekunden.
	 * @param onCustomDamage Optionaler Callback für individuelle Health-Systeme: `(sprite, dmg) -> Void`.
	 */
	public function applyHazardDamage(sprite:FlxSprite, elapsed:Float, ?onCustomDamage:(sprite:FlxSprite, damage:Float) -> Void):Void {
		if (!isHazardous || damagePerSecond <= 0.0 || sprite == null)
			return;

		if (isOverlapping(sprite)) {
			var dmg = damagePerSecond * elapsed;
			if (onCustomDamage != null) {
				onCustomDamage(sprite, dmg);
			} else {
				sprite.hurt(dmg);
			}
		}
	}

	private function set_liquidType(value:HazardLiquidType):HazardLiquidType {
		liquidType = value;
		if (shaderInstance != null) {
			shaderInstance.applyType(value);
		}
		return liquidType;
	}
}
