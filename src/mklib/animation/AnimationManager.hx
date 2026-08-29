package mklib.animation;

import flixel.FlxSprite;
import mklib.animation.AnimationTypes.SpriteSheetData;
import mklib.animation.AnimationTypes.AnimationClip;
import AnimationRegistry;

/**
 * Zentraler Manager und Hilfsklasse zur Anwendung von Spritesheets und Animationen auf `FlxSprite`-Instanzen.
 *
 * Verwaltet das automatische Laden von Grafiken, das Hinzufügen von AnimationClips
 * sowie das Abspielen der Standard-Animation aus der `AnimationRegistry`.
 * Kann auch als Static Extension (`using mklib.animation.AnimationManager;`) genutzt werden.
 */
class AnimationManager {
	/**
	 * Lädt die Grafik und registriert alle Animationen aus der `AnimationRegistry` auf dem übergebenen Sprite.
	 *
	 * @param sprite Das Ziel-Sprite (z. B. `FlxSprite`, `EntitySprite`, `EntityNapeSprite`).
	 * @param animKey Der Schlüssel in `AnimationRegistry.db` (z. B. "Fire").
	 * @param forceGraphic Falls `true`, wird `loadGraphic` auch aufgerufen, wenn `sprite.graphic != null` ist.
	 * @return `true`, wenn die Animation erfolgreich gefunden und zugewiesen wurde, andernfalls `false`.
	 */
	public static function apply(sprite:FlxSprite, animKey:String, forceGraphic:Bool = false):Bool {
		if (sprite == null || animKey == null) {
			return false;
		}

		if (AnimationRegistry.db != null && AnimationRegistry.db.exists(animKey)) {
			var data:SpriteSheetData = AnimationRegistry.db.get(animKey);
			return applyData(sprite, data, forceGraphic);
		}
		return false;
	}

	/**
	 * Wendet ein konkretes `SpriteSheetData`-Objekt direkt auf ein Sprite an.
	 *
	 * @param sprite Das Ziel-Sprite.
	 * @param data Die anzuwendenden Spritesheet- und Animationsdaten.
	 * @param forceGraphic Falls `true`, wird `loadGraphic` auch aufgerufen, wenn `sprite.graphic != null` ist.
	 * @return `true`, wenn die Daten erfolgreich zugewiesen wurden, andernfalls `false`.
	 */
	public static function applyData(sprite:FlxSprite, data:SpriteSheetData, forceGraphic:Bool = false):Bool {
		if (sprite == null || data == null) {
			return false;
		}

		if ((sprite.graphic == null || forceGraphic) && data.imagePath != null && data.config != null) {
			sprite.loadGraphic(data.imagePath, true, data.config.width, data.config.height);
		}

		if (data.animations != null) {
			for (clip in data.animations) {
				sprite.animation.add(clip.name, clip.frames, clip.fps, clip.loop, clip.flipX, clip.flipY);
			}
		}

		if (data.defaultAnimation != null) {
			sprite.animation.play(data.defaultAnimation);
		}

		return true;
	}

	/**
	 * Prüft, ob ein Animationsschlüssel in der `AnimationRegistry` existiert.
	 *
	 * @param animKey Der Schlüssel (z. B. "Fire").
	 * @return `true`, falls vorhanden.
	 */
	public static function exists(animKey:String):Bool {
		if (animKey == null || AnimationRegistry.db == null) {
			return false;
		}
		return AnimationRegistry.db.exists(animKey);
	}

	/**
	 * Liefert die `SpriteSheetData` für einen Schlüssel aus der `AnimationRegistry` oder `null`.
	 *
	 * @param animKey Der Name der Animationsdefinition (z. B. "Fire").
	 * @return Die `SpriteSheetData` oder `null`.
	 */
	public static function get(animKey:String):Null<SpriteSheetData> {
		if (animKey != null && AnimationRegistry.db != null && AnimationRegistry.db.exists(animKey)) {
			return AnimationRegistry.db.get(animKey);
		}
		return null;
	}
}
