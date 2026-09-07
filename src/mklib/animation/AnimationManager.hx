package mklib.animation;

import flixel.FlxSprite;
import mklib.animation.AnimationTypes.SpriteSheetData;
import mklib.animation.AnimationTypes.AnimationClip;
import haxe.io.Path;
import haxe.Json;
import AnimationRegistry;

/**
 * Zentraler Manager und Hilfsklasse zur Anwendung von Spritesheets und Animationen auf `FlxSprite`-Instanzen.
 *
 * Verwaltet das automatische Laden von Grafiken, das Hinzufügen von AnimationClips
 * sowie das Abspielen der Standard-Animation aus der `AnimationRegistry` bzw. direkt aus `assets/data/animations/`.
 * Kann auch als Static Extension (`using mklib.animation.AnimationManager;`) genutzt werden.
 */
class AnimationManager {
	/**
	 * Standard-Ordnerpfad zu den Animations-JSON-Dateien.
	 */
	public static var animationsFolder:String = "assets/data/animations";

	/**
	 * Laufzeit-Cache für dynamisch nachgeladene oder modifizierte Spritesheet-Daten.
	 */
	public static var runtimeCache:Map<String, SpriteSheetData> = new Map();

	/**
	 * Normalisiert einen Animations-Schlüssel (entfernt Verzeichnispfade und die `.json`-Endung).
	 * Z. B. "assets/data/animations/Hero.json" -> "Hero" oder "Hero.json" -> "Hero".
	 *
	 * @param animKey Der rohe Schlüssel oder Dateipfad.
	 * @return Der bereinigte Schlüsselname.
	 */
	public static function cleanKey(animKey:String):String {
		if (animKey == null) {
			return "";
		}
		var normalized = animKey.split("\\").join("/");
		return Path.withoutExtension(Path.withoutDirectory(normalized));
	}

	/**
	 * Lädt die Grafik und registriert alle Animationen aus der `AnimationRegistry`
	 * bzw. den JSON-Dateien auf dem übergebenen Sprite.
	 *
	 * @param sprite Das Ziel-Sprite (z. B. `FlxSprite`, `EntitySprite`, `EntityNapeSprite`).
	 * @param animKey Der Schlüssel oder Dateiname der Animation (z. B. "Hero", "Hero.json", "Warg").
	 * @param forceGraphic Falls `true` (Standard), wird `loadGraphic` aufgerufen, um das korrekte Spritesheet zu laden.
	 * @return `true`, wenn die Animation erfolgreich gefunden und zugewiesen wurde, andernfalls `false`.
	 */
	public static function apply(sprite:FlxSprite, animKey:String, forceGraphic:Bool = true):Bool {
		if (sprite == null || animKey == null) {
			return false;
		}

		var data:Null<SpriteSheetData> = get(animKey);
		if (data != null) {
			return applyData(sprite, data, forceGraphic);
		}
		return false;
	}

	/**
	 * Wendet ein konkretes `SpriteSheetData`-Objekt direkt auf ein Sprite an.
	 *
	 * @param sprite Das Ziel-Sprite.
	 * @param data Die anzuwendenden Spritesheet- und Animationsdaten.
	 * @param forceGraphic Falls `true` (Standard), wird `loadGraphic` aufgerufen, wenn nötig oder erzwungen.
	 * @return `true`, wenn die Daten erfolgreich zugewiesen wurden, andernfalls `false`.
	 */
	public static function applyData(sprite:FlxSprite, data:SpriteSheetData, forceGraphic:Bool = true):Bool {
		if (sprite == null || data == null) {
			return false;
		}

		if (data.imagePath != null && data.config != null) {
			var shouldLoad:Bool = forceGraphic || sprite.graphic == null;
			if (!shouldLoad && sprite.graphic != null && sprite.graphic.key != data.imagePath) {
				shouldLoad = true;
			}
			if (shouldLoad) {
				sprite.loadGraphic(data.imagePath, true, data.config.width, data.config.height);
			}
		}

		if (data.animations != null) {
			for (clip in data.animations) {
				sprite.animation.add(clip.name, clip.frames, clip.fps, clip.loop, clip.flipX, clip.flipY);
			}
		}

		if (data.defaultAnimation != null && sprite.animation.getByName(data.defaultAnimation) != null) {
			sprite.animation.play(data.defaultAnimation);
		} else if (data.animations != null && data.animations.length > 0) {
			sprite.animation.play(data.animations[0].name);
		}

		return true;
	}

	/**
	 * Prüft, ob ein Animationsschlüssel in der `AnimationRegistry` oder als JSON-Datei existiert.
	 *
	 * @param animKey Der Schlüssel (z. B. "Hero", "Warg").
	 * @return `true`, falls vorhanden.
	 */
	public static function exists(animKey:String):Bool {
		return get(animKey) != null;
	}

	/**
	 * Liefert die `SpriteSheetData` für einen Schlüssel aus dem Cache, der `AnimationRegistry`
	 * oder lädt die entsprechende JSON-Datei zur Laufzeit nach.
	 *
	 * @param animKey Der Name oder Dateiname der Animationsdefinition (z. B. "Hero", "Hero.json").
	 * @return Die `SpriteSheetData` oder `null`.
	 */
	public static function get(animKey:String):Null<SpriteSheetData> {
		if (animKey == null) {
			return null;
		}

		var key = cleanKey(animKey);

		// 1. Laufzeit-Cache prüfen
		if (runtimeCache != null && runtimeCache.exists(key)) {
			return runtimeCache.get(key);
		}

		// 2. In der statischen AnimationRegistry (Compile-Time) prüfen
		if (AnimationRegistry.db != null) {
			if (AnimationRegistry.db.exists(key)) {
				return AnimationRegistry.db.get(key);
			}
			if (AnimationRegistry.db.exists(animKey)) {
				return AnimationRegistry.db.get(animKey);
			}
		}

		// 3. Fallback: Zur Laufzeit direkt aus assets/data/animations/$key.json nachladen
		var loadedData = loadFromJsonFile(key);
		if (loadedData != null) {
			if (runtimeCache == null) {
				runtimeCache = new Map();
			}
			runtimeCache.set(key, loadedData);
			return loadedData;
		}

		return null;
	}

	/**
	 * Lädt eine JSON-Animationsdatei zur Laufzeit ein und normalisiert den darin enthaltenen Bildpfad.
	 *
	 * @param key Bereinigter Schlüsselname ohne Pfad und Endung (z. B. "Hero").
	 * @return Die geparsten Spritesheet-Daten oder `null`.
	 */
	public static function loadFromJsonFile(key:String):Null<SpriteSheetData> {
		if (key == null || key == "") {
			return null;
		}

		var candidates:Array<String> = [
			Path.join([animationsFolder, key + ".json"]),
			animationsFolder + "/" + key + ".json",
			"assets/data/animations/" + key + ".json"
		];

		var jsonStr:Null<String> = null;

		for (path in candidates) {
			#if sys
			if (sys.FileSystem.exists(path)) {
				try {
					jsonStr = sys.io.File.getContent(path);
					if (jsonStr != null) {
						break;
					}
				} catch (e:Dynamic) {}
			}
			#end
			#if openfl
			if (jsonStr == null && openfl.utils.Assets.exists(path)) {
				try {
					jsonStr = openfl.utils.Assets.getText(path);
					if (jsonStr != null) {
						break;
					}
				} catch (e:Dynamic) {}
			}
			#end
		}

		if (jsonStr != null) {
			try {
				var parsed:Dynamic = Json.parse(jsonStr);
				if (parsed != null && parsed.imagePath != null) {
					var rawPath:String = Std.string(parsed.imagePath);
					var normalized = rawPath.split("\\").join("/");
					var assetIdx = normalized.indexOf("assets/");
					parsed.imagePath = (assetIdx != -1) ? normalized.substr(assetIdx) : normalized;
				}
				return cast parsed;
			} catch (e:Dynamic) {}
		}

		return null;
	}
}
