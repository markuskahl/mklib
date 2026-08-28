package mklib.effect;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import mklib.effect.shader.WaterReflectionShader;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Vollständiges 2D-Wasserflächen-Spielobjekt (`FlxSprite`), das die Spielwelt (Tiles, Spielfiguren,
 * Deko) oberhalb der Wasseroberfläche in Echtzeit erfasst, vertikal spiegelt und mit dem
 * hardwarebeschleunigten `WaterReflectionShader` (Wellen, Gischt, Tönung, Tiefenabnahme) rendert.
 */
class WaterReflectionPlane extends FlxSprite {
	/**
	 * Die Instanz des zugeordneten GPU-Wellen-Shaders.
	 */
	public var shaderInstance(default, null):WaterReflectionShader;

	/**
	 * Liste expliziter Layer, Gruppen oder Sprites, die im Wasser gespiegelt werden sollen.
	 * Falls leer und `autoCaptureState = true`, werden automatisch alle Mitglieder des aktuellen States vor dieser Ebene erfasst.
	 */
	public var reflectTargets:Array<Dynamic> = [];

	/**
	 * Bestimmt, ob automatisch alle sichtbaren State-Mitglieder vor der Wasserebene erfasst werden sollen.
	 */
	public var autoCaptureState:Bool = true;

	/**
	 * Grundfarbe und Anfangstransparenz des Wassers.
	 */
	public var waterBaseColor:FlxColor;

	// Interne Render-Puffer & Matrizen
	private var _reflectionBitmap:BitmapData;
	private var _drawMatrix:Matrix;
	private var _clipRect:Rectangle;
	private var _originPoint:Point;

	/**
	 * Erstellt eine neue spiegelnde Wasserfläche an den angegebenen Weltkoordinaten.
	 *
	 * @param x X-Koordinate der Wasserfläche in Weltpixeln.
	 * @param y Y-Koordinate der Wasseroberfläche in Weltpixeln.
	 * @param width Breite der Wasserfläche in Pixeln.
	 * @param height Tiefe / Höhe der Wasserfläche in Pixeln.
	 * @param waterColor Grundtönung des Wassers (Standard: Halbtransparentes Blau 0x66103560).
	 */
	public function new(x:Float, y:Float, width:Int, height:Int, waterColor:FlxColor = 0x66103560) {
		super(x, y);

		this.waterBaseColor = waterColor;
		makeGraphic(width, height, waterColor, true);

		_drawMatrix = new Matrix();
		_clipRect = new Rectangle(0, 0, width, height);
		_originPoint = new Point(0, 0);

		shaderInstance = new WaterReflectionShader();
		// Modus 2: Reine Wellenverzerrung, da die Spiegelung direkt im Bitmap-Puffer berechnet wird
		shaderInstance.setMode(WaterReflectionMode.WAVE_DISTORTION_ONLY);
		shaderInstance.setWaveParams(3.0, 25.0, 0.04, 0.5);
		shaderInstance.setWaterColor(waterColor, 0.4);
		shaderInstance.setFoam(0.02, 0xFFFFFFFF);
		shaderInstance.setFade(1.5, 0.2);
		this.shader = shaderInstance;
	}

	/**
	 * Fügt ein Ziel (z. B. `TileLayer`, `EntityLayer`, `Hero`, `FlxGroup`) zur Reflexion hinzu.
	 */
	public function addReflectTarget(target:Dynamic):Void {
		if (target != null && reflectTargets.indexOf(target) == -1) {
			reflectTargets.push(target);
		}
	}

	/**
	 * Entfernt ein Ziel aus der Reflexionsliste.
	 */
	public function removeReflectTarget(target:Dynamic):Void {
		reflectTargets.remove(target);
	}

	/**
	 * Leert die Liste spezifischer Reflexionsziele.
	 */
	public function clearReflectTargets():Void {
		reflectTargets = [];
	}

	/**
	 * Aktualisiert die Wellenzeit des Shaders.
	 */
	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (shaderInstance != null) {
			shaderInstance.update(elapsed);
		}
	}

	/**
	 * Rendert die Spiegelung der darüberliegenden Szene in den Puffer und zeichnet das Wasser.
	 */
	override public function draw():Void {
		updateReflectionBitmap();
		super.draw();
	}

	/**
	 * Erfasst alle Objekte oberhalb der Wasserlinie und zeichnet sie vertikal gespiegelt in den internen Bitmap-Puffer.
	 */
	private function updateReflectionBitmap():Void {
		var bw = Std.int(width);
		var bh = Std.int(height);
		if (bw <= 0 || bh <= 0)
			return;

		if (_reflectionBitmap == null || _reflectionBitmap.width != bw || _reflectionBitmap.height != bh) {
			if (_reflectionBitmap != null) {
				_reflectionBitmap.dispose();
			}
			_reflectionBitmap = new BitmapData(bw, bh, true, waterBaseColor);
		} else {
			_reflectionBitmap.fillRect(_reflectionBitmap.rect, waterBaseColor);
		}

		// 1. Explizite Targets spiegeln
		if (reflectTargets != null && reflectTargets.length > 0) {
			for (target in reflectTargets) {
				renderTargetReflection(target, bw, bh);
			}
		} else if (autoCaptureState && FlxG.state != null && FlxG.state.members != null) {
			// 2. Automatisch alle Mitglieder des aktuellen States vor dieser Ebene spiegeln
			for (member in FlxG.state.members) {
				if (member == this)
					break; // Nur Objekte oberhalb/vor der Wasserebene
				if (member != null && Std.isOfType(member, FlxBasic)) {
					renderTargetReflection(member, bw, bh);
				}
			}
		}

		// Den spiegelnden Puffer in die Flixel-Grafik übertragen
		if (graphic != null && graphic.bitmap != null) {
			graphic.bitmap.copyPixels(_reflectionBitmap, _reflectionBitmap.rect, _originPoint);
		}
	}

	/**
	 * Rekursive Spiegelung von Gruppen und Sprites.
	 */
	private function renderTargetReflection(target:Dynamic, bw:Int, bh:Int):Void {
		if (target == null)
			return;

		// 1. FlxSpriteGroup
		if (Std.isOfType(target, FlxSpriteGroup)) {
			var spriteGroup:FlxSpriteGroup = cast target;
			if (spriteGroup.exists && spriteGroup.visible && spriteGroup.group != null) {
				for (m in spriteGroup.group.members) {
					if (m != null && m.exists && m.visible && m.alpha > 0.01 && m != this) {
						renderSpriteReflection(m, bw, bh);
					}
				}
			}
			return;
		}

		// 2. Generische FlxTypedGroup
		if (Std.isOfType(target, FlxTypedGroup)) {
			var typedGroup:FlxTypedGroup<Dynamic> = cast target;
			if (typedGroup.exists && typedGroup.visible && typedGroup.members != null) {
				for (m in typedGroup.members) {
					if (m != null) {
						renderTargetReflection(m, bw, bh);
					}
				}
			}
			return;
		}

		// 3. Einzelnes FlxSprite
		if (Std.isOfType(target, FlxSprite)) {
			var sprite:FlxSprite = cast target;
			if (sprite.exists && sprite.visible && sprite.alpha > 0.01 && sprite != this) {
				renderSpriteReflection(sprite, bw, bh);
			}
			return;
		}
	}

	/**
	 * Zeichnet ein einzelnes Sprite vertikal gespiegelt in den internen Reflexions-Puffer.
	 */
	private function renderSpriteReflection(sprite:FlxSprite, bw:Int, bh:Int):Void {
		// Horizontale Sichtbarkeit prüfen
		if (sprite.x + sprite.width < this.x || sprite.x > this.x + this.width) {
			return;
		}

		// Vertikale Sichtbarkeit oberhalb der Wasserlinie prüfen
		// Das Sprite muss sich im Bereich zwischen (this.y - this.height) und this.y befinden
		if (sprite.y > this.y || (sprite.y + sprite.height) < (this.y - this.height)) {
			return;
		}

		var srcW = (sprite.frame != null && sprite.frame.frame != null) ? sprite.frame.frame.width : sprite.width;
		var srcH = (sprite.frame != null && sprite.frame.frame != null) ? sprite.frame.frame.height : sprite.height;

		var destX = (sprite.x - this.x);
		var destY = (this.y - (sprite.y + sprite.height));
		var destW = sprite.width;
		var destH = sprite.height;

		// Clip-Rechteck exakt auf das gespiegelte Ziel-Sprite begrenzen (verhindert Tilesheet-Überlauf)
		_clipRect.setTo(destX, destY, destW, destH);

		// An den Grenzen der Wasserebene abschneiden
		if (_clipRect.x < 0) {
			_clipRect.width += _clipRect.x;
			_clipRect.x = 0;
		}
		if (_clipRect.y < 0) {
			_clipRect.height += _clipRect.y;
			_clipRect.y = 0;
		}
		if (_clipRect.x + _clipRect.width > bw) {
			_clipRect.width = bw - _clipRect.x;
		}
		if (_clipRect.y + _clipRect.height > bh) {
			_clipRect.height = bh - _clipRect.y;
		}

		if (_clipRect.width <= 0 || _clipRect.height <= 0) {
			return;
		}

		_drawMatrix.identity();

		// Frame-Offset eines Spritesheets abziehen
		if (sprite.frame != null && sprite.frame.frame != null) {
			_drawMatrix.translate(-sprite.frame.frame.x, -sprite.frame.frame.y);
		}

		var scaleX = sprite.scale.x * (sprite.flipX ? -1 : 1);
		var scaleY = sprite.scale.y * (sprite.flipY ? -1 : 1);

		// Vertikal invertieren (Spiegelung)
		_drawMatrix.scale(scaleX, -scaleY);

		// Verschiebung in das lokale Koordinatensystem der Wasserebene
		var posX = (sprite.x - this.x);
		var posY = (this.y - sprite.y);

		_drawMatrix.translate(posX, posY);

		var ct:openfl.geom.ColorTransform = null;
		if (sprite.alpha < 0.999 || sprite.color != 0xFFFFFF) {
			ct = new openfl.geom.ColorTransform(sprite.color.redFloat, sprite.color.greenFloat, sprite.color.blueFloat, sprite.alpha);
		}

		if (sprite.frame != null && sprite.frame.parent != null && sprite.frame.parent.bitmap != null) {
			_reflectionBitmap.draw(sprite.frame.parent.bitmap, _drawMatrix, ct, null, _clipRect, false);
		} else if (sprite.graphic != null && sprite.graphic.bitmap != null) {
			_reflectionBitmap.draw(sprite.graphic.bitmap, _drawMatrix, ct, null, _clipRect, false);
		}
	}

	/**
	 * Konfiguriert die Welleneigenschaften der Wasserfläche.
	 *
	 * @param speed Ausbreitungsgeschwindigkeit der Wellen.
	 * @param frequency Frequenz / Dichte der Wellenkuppen.
	 * @param amplitude Maximale Wellenauslenkung (Verzerrungsstärke, z. B. 0.04).
	 * @param secondaryWave Überlagerungsfaktor für Kreuzwellen (Standard: 0.5).
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
	 * Setzt die Wassertönung.
	 */
	public function setWaterColor(color:FlxColor, tintIntensity:Float = 0.4):Void {
		this.waterBaseColor = color;
		if (shaderInstance != null) {
			shaderInstance.setWaterColor(color, tintIntensity);
		}
	}

	/**
	 * Setzt das Tiefenausblenden (Fade).
	 */
	public function setFade(depthFactor:Float, minAlpha:Float = 0.2):Void {
		if (shaderInstance != null) {
			shaderInstance.setFade(depthFactor, minAlpha);
		}
	}

	/**
	 * Gibt Ressourcen frei.
	 */
	override public function destroy():Void {
		if (_reflectionBitmap != null) {
			_reflectionBitmap.dispose();
			_reflectionBitmap = null;
		}
		_drawMatrix = null;
		_clipRect = null;
		_originPoint = null;
		reflectTargets = null;
		shaderInstance = null;
		super.destroy();
	}
}
