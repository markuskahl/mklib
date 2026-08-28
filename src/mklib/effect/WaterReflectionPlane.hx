package mklib.effect;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import mklib.effect.shader.WaterReflectionShader;

/**
 * Fertig konfiguriertes Wasserflächen-Spielobjekt (`FlxSprite`) mit GPU-Reflexions- und Wellen-Shader.
 *
 * Kann direkt an beliebigen Weltkoordinaten (z. B. Seen, Flüssen, Pfützen) platziert werden
 * und synchronisiert die Shader-Parameter, Wellenbewegung und Kamera-Position automatisch pro Frame.
 */
class WaterReflectionPlane extends FlxSprite {
	/**
	 * Die Instanz des zugeordneten GPU-Shaders.
	 */
	public var shaderInstance(default, null):WaterReflectionShader;

	/**
	 * Bestimmt, ob die Wasseroberfläche pro Frame automatisch mit der Kamera synchronisiert wird.
	 */
	public var autoSyncCamera:Bool = true;

	/**
	 * Optionale Referenz auf eine spezifische Kamera (Standard: `FlxG.camera`).
	 */
	public var targetCamera:FlxCamera;

	/**
	 * Erstellt eine neue Wasserfläche an den angegebenen Weltkoordinaten.
	 *
	 * @param x X-Koordinate der Wasserfläche in Weltpixeln.
	 * @param y Y-Koordinate der Wasseroberfläche in Weltpixeln.
	 * @param width Breite der Wasserfläche in Pixeln.
	 * @param height Tiefe / Höhe der Wasserfläche in Pixeln.
	 * @param waterColor Grundfarbe des Wassers (Standard: Halbtransparentes Blau 0x66104080).
	 */
	public function new(x:Float, y:Float, width:Int, height:Int, waterColor:FlxColor = 0x66104080) {
		super(x, y);

		makeGraphic(width, height, waterColor);

		shaderInstance = new WaterReflectionShader();
		this.shader = shaderInstance;

		// Standardmäßig auf die Oberkante des Sprites als Wasserlinie kalibrieren
		shaderInstance.setWaterLevel(0.0);
		shaderInstance.setWaterColor(waterColor, 0.4);
	}

	/**
	 * Aktualisiert die Wellenanimation und die Kamerakoordinaten des Shaders.
	 *
	 * @param elapsed Vergangene Frame-Zeit in Sekunden.
	 */
	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (shaderInstance != null) {
			shaderInstance.update(elapsed);

			if (autoSyncCamera) {
				var cam = (targetCamera != null) ? targetCamera : FlxG.camera;
				if (cam != null) {
					shaderInstance.syncWithCamera(this.y, cam);
				}
			}
		}
	}

	/**
	 * Konfiguriert die Welleneigenschaften der Wasserfläche.
	 *
	 * @param speed Ausbreitungsgeschwindigkeit der Wellen.
	 * @param frequency Frequenz / Dichte der Wellenkuppen.
	 * @param amplitude Maximale Wellenauslenkung (Verzerrungsstärke).
	 * @param secondaryWave Überlagerungsfaktor für Kreuzwellen.
	 */
	public function setWaveParams(speed:Float, frequency:Float, amplitude:Float, secondaryWave:Float = 0.5):Void {
		if (shaderInstance != null) {
			shaderInstance.setWaveParams(speed, frequency, amplitude, secondaryWave);
		}
	}

	/**
	 * Setzt die Schaum- / Glanzkante an der Wasseroberfläche.
	 *
	 * @param thickness Dicke der Schaumlinie.
	 * @param color Farbe des Schaums.
	 */
	public function setFoam(thickness:Float, ?color:FlxColor):Void {
		if (shaderInstance != null) {
			shaderInstance.setFoam(thickness, color);
		}
	}

	/**
	 * Gibt Ressourcen frei.
	 */
	override public function destroy():Void {
		shaderInstance = null;
		targetCamera = null;
		super.destroy();
	}
}
