package mklib.effect;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import mklib.effect.shader.WaterReflectionShader;

/**
 * Automatisches Reflexions-Begleiter-Sprite für einzelne Spielfiguren und Entities (`FlxSprite`).
 *
 * Platziert sich automatisch unterhalb des Ziel-Entities, spiegelt dessen Grafik (`flipY = true`),
 * synchronisiert Animationsframes und wendet den `WaterReflectionShader` mit Wellenverzerrung und Transparenz an.
 */
class EntityWaterReflection extends FlxSprite {
	/**
	 * Das überwachte Quell-Sprite (z. B. `Hero` oder `EntitySprite`).
	 */
	public var target(default, set):FlxSprite;

	/**
	 * Die Instanz des zugeordneten GPU-Wellen-Shaders.
	 */
	public var shaderInstance(default, null):WaterReflectionShader;

	/**
	 * Zusätzlicher Versatz in X-Richtung relativ zum Target.
	 */
	public var offsetX:Float = 0;

	/**
	 * Zusätzlicher Versatz in Y-Richtung (Standard: 0 = direkt an den Füßen des Targets).
	 */
	public var offsetY:Float = 0;

	/**
	 * Bestimmt, ob die Reflexionshöhe gestaucht werden soll (z. B. 0.75 für isometrische/schräge Perspektive).
	 */
	public var verticalScale(default, set):Float = 1.0;

	/**
	 * Erstellt ein neues Reflexions-Sprite für ein bestimmtes Ziel-Sprite.
	 *
	 * @param target Das zu spiegelnde Entity / FlxSprite.
	 * @param alpha Grundtransparenz der Reflexion (Standard: 0.6).
	 * @param waterColor Optionale bläuliche Wassertönung (Standard: 0x66104080).
	 */
	public function new(?target:FlxSprite, alpha:Float = 0.6, waterColor:FlxColor = 0x66104080) {
		super();

		this.alpha = alpha;
		this.flipY = true;

		shaderInstance = new WaterReflectionShader();
		shaderInstance.setMode(WaterReflectionMode.WAVE_DISTORTION_ONLY);
		shaderInstance.setWaveParams(3.5, 25.0, 0.015, 0.4);
		shaderInstance.setWaterColor(waterColor, 0.35);
		this.shader = shaderInstance;

		if (target != null) {
			this.target = target;
		}
	}

	/**
	 * Setzt das Ziel-Sprite und synchronisiert sofort die Grafikabmessungen.
	 */
	function set_target(value:FlxSprite):FlxSprite {
		target = value;
		if (target != null) {
			syncWithTarget();
		}
		return target;
	}

	/**
	 * Setzt die vertikale Skalierung / Stauchung der Reflexion.
	 */
	function set_verticalScale(value:Float):Float {
		verticalScale = value;
		scale.y = verticalScale;
		return verticalScale;
	}

	/**
	 * Aktualisiert Frame, Position und Shader-Animation.
	 *
	 * @param elapsed Vergangene Frame-Zeit in Sekunden.
	 */
	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (target != null) {
			syncWithTarget();
		}

		if (shaderInstance != null) {
			shaderInstance.update(elapsed);
		}
	}

	/**
	 * Synchronisiert Frame, Frameset, Sichtbarkeit und Position mit dem Ziel-Sprite.
	 */
	public function syncWithTarget():Void {
		if (target == null)
			return;

		this.visible = target.visible && target.alive && target.exists;
		if (!this.visible)
			return;

		// Grafik / Frames synchronisieren, falls geändert
		if (this.frames != target.frames) {
			this.frames = target.frames;
		}
		if (this.animation != null && target.animation != null && target.animation.curAnim != null) {
			if (this.animation.curAnim == null || this.animation.curAnim.name != target.animation.curAnim.name) {
				this.animation.play(target.animation.curAnim.name);
			}
			if (this.animation.curAnim != null) {
				this.animation.curAnim.curFrame = target.animation.curAnim.curFrame;
			}
		} else if (this.frame != target.frame) {
			this.frame = target.frame;
		}

		this.flipX = target.flipX;
		this.flipY = true;

		// Position direkt an der Fußkante des Targets ausrichten
		this.x = target.x + offsetX;
		this.y = target.y + (target.height * verticalScale) + offsetY;
	}

	/**
	 * Konfiguriert die Wellenparameter der Entity-Reflexion.
	 *
	 * @param speed Ausbreitungsgeschwindigkeit der Wellen.
	 * @param frequency Frequenz / Dichte der Wellen.
	 * @param amplitude Maximale Wellenauslenkung (Verzerrungsstärke).
	 */
	public function setWaveParams(speed:Float, frequency:Float, amplitude:Float):Void {
		if (shaderInstance != null) {
			shaderInstance.setWaveParams(speed, frequency, amplitude);
		}
	}

	/**
	 * Gibt Ressourcen frei.
	 */
	override public function destroy():Void {
		target = null;
		shaderInstance = null;
		super.destroy();
	}
}
