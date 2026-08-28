package mklib.entity;

import flixel.FlxG;
import flixel.FlxSprite;
import mklib.animation.AnimationTypes.SpriteSheetData;
import mklib.animation.AnimationTypes.AnimationClip;
import mklib.save.SaveManager;
import mklib.state.State;
import AnimationRegistry;

/**
 * Basisklasse für visuelle Entities, die aus einem LDtk-Level geladen werden.
 *
 * Erbt von `FlxSprite` und synchronisiert automatisch Position, Abmessungen,
 * die eindeutige Instanz-ID (`iid`), die Referenz auf den aktuellen `State`
 * sowie den Pfad zur zugewiesenen Grafikdatei (`graphicPath`).
 */
class EntitySprite extends FlxSprite {
	/**
	 * Die zugrundeliegende LDtk-Entity-Instanz mit Rohdaten und Feldern.
	 */
	public var _entity:ldtk.Entity;

	/**
	 * Die weltweit eindeutige Instanz-ID (IID) der Entity aus LDtk.
	 */
	public var iid:String;

	/**
	 * Referenz auf den aktuellen `mklib.state.State`, sofern aktiv.
	 */
	public var state:State;

	/**
	 * Der relative Pfad zur Grafikdatei (relativ zur LDtk-Projektdatei),
	 * falls der Entity in LDtk ein Tile zugewiesen ist, andernfalls `null`.
	 */
	public var graphicPath:Null<String>;

	/**
	 * Gibt an, ob die Entity über eine zugewiesene Grafikdatei in LDtk verfügt.
	 */
	public var hasGraphic:Bool = false;

	/**
	 * Erstellt eine neue Instanz von `EntitySprite` anhand einer LDtk-Entity.
	 *
	 * @param entity Die aus dem LDtk-Level geladene Entity-Definition.
	 */
	public function new(entity:ldtk.Entity) {
		_entity = entity;
		super(entity.pixelX, entity.pixelY);
		iid = entity.iid;
		width = entity.width;
		height = entity.height;
		if (FlxG.state != null && Std.isOfType(FlxG.state, State)) {
			state = cast FlxG.state;
		}

		graphicPath = getGraphicPath();

		if (hasGraphic) {
			loadGraphic(graphicPath, true, _entity.tileInfos.w, _entity.tileInfos.h);
		}

		if (hasField("Animations")) {
			initAnimation(getField("Animations"));
		}
	}

	/**
	 * Liest den Wert eines benutzerdefinierten LDtk-Feldes (`fieldInstances`) aus.
	 *
	 * @param identifier Der Bezeichner des Feldes in LDtk (z. B. "image", "speed").
	 * @return Der Wert des Feldes oder `null`, falls nicht vorhanden.
	 */
	public function getField(identifier:String):Dynamic {
		if (_entity != null && _entity.json != null && _entity.json.fieldInstances != null) {
			for (inst in _entity.json.fieldInstances) {
				if (inst.__identifier == identifier) {
					return inst.__value;
				}
			}
		}
		return null;
	}

	/**
	 * Prüft, ob ein benutzerdefiniertes LDtk-Feld für diese Entity existiert.
	 *
	 * @param identifier Der Bezeichner des Feldes in LDtk.
	 * @return `true`, wenn das Feld vorhanden ist, andernfalls `false`.
	 */
	public function hasField(identifier:String):Bool {
		if (_entity != null && _entity.json != null && _entity.json.fieldInstances != null) {
			for (inst in _entity.json.fieldInstances) {
				if (inst.__identifier == identifier) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Ermittelt und normalisiert den Pfad zur Grafikdatei (beginnend mit `assets/`),
	 * falls der Entity in LDtk ein Tile zugewiesen ist. Setzt zudem das Flag `hasGraphic`.
	 *
	 * @return Der aufgelöste Asset-Pfad zur Bilddatei oder `null`.
	 */
	public function getGraphicPath():Null<String> {
		hasGraphic = false;

		if (_entity == null || _entity.tileInfos == null) {
			return null;
		}

		var proj:ldtk.Project = (state != null && state.project != null) ? state.project : @:privateAccess _entity.untypedProject;
		if (proj == null) {
			return null;
		}

		var tilesetDef = proj.getTilesetDefJson(_entity.tileInfos.tilesetUid);
		if (tilesetDef == null || tilesetDef.relPath == null) {
			return null;
		}

		var rawPath:String = (proj.projectDir != null && proj.projectDir.length > 0) ? (proj.projectDir + "/" + tilesetDef.relPath) : tilesetDef.relPath;
		var normalized:String = haxe.io.Path.normalize(rawPath);
		if (!StringTools.startsWith(normalized, "assets/")) {
			if (StringTools.startsWith(normalized, "/")) {
				normalized = "assets" + normalized;
			} else {
				normalized = "assets/" + normalized;
			}
		}
		hasGraphic = true;
		return normalized;
	}

	/**
	 * Initialisiert und startet Animationen aus der `AnimationRegistry` für diese Entity.
	 *
	 * @param animKey Name/Schlüssel der Animationsdefinition in `AnimationRegistry.db` (z. B. "Fire").
	 *                Falls nicht angegeben, wird das LDtk-Feld `"Animations"` verwendet.
	 */
	public function initAnimation(?animKey:String):Void {
		if (animKey == null) {
			animKey = getField("Animations");
		}
		if (animKey == null) {
			return;
		}

		if (AnimationRegistry.db != null && AnimationRegistry.db.exists(animKey)) {
			var spritesheetData:SpriteSheetData = AnimationRegistry.db.get(animKey);
			if (spritesheetData != null) {
				if (graphic == null && spritesheetData.imagePath != null && spritesheetData.config != null) {
					loadGraphic(spritesheetData.imagePath, true, spritesheetData.config.width, spritesheetData.config.height);
				}
				if (spritesheetData.animations != null) {
					for (sprite in spritesheetData.animations) {
						animation.add(sprite.name, sprite.frames, sprite.fps, sprite.loop, sprite.flipX, sprite.flipY);
					}
				}
				if (spritesheetData.defaultAnimation != null) {
					animation.play(spritesheetData.defaultAnimation);
				}
			}
		}
	}

	/**
	 * Markiert diese Entity im `SaveManager` als zerstört/aufgesammelt,
	 * sodass sie beim erneuten Betreten des Levels nicht mehr gespawnt wird.
	 *
	 * @param killSprite Falls `true` (Standard), wird sofort `kill()` auf diesem Sprite aufgerufen.
	 */
	public function markDestroyed(killSprite:Bool = true):Void {
		if (iid != null) {
			var lvlName:Null<String> = (state != null) ? state.levelName : null;
			SaveManager.markEntityDestroyed(iid, lvlName);
		}
		if (killSprite) {
			kill();
		}
	}

	/**
	 * Prüft, ob diese Entity im aktuellen Save-Zustand als zerstört markiert ist.
	 */
	public function isSaveDestroyed():Bool {
		if (iid == null) {
			return false;
		}
		var lvlName:Null<String> = (state != null) ? state.levelName : null;
		return SaveManager.isEntityDestroyed(iid, lvlName);
	}
}
