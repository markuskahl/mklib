package mklib.entity;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import mklib.animation.AnimationManager;
import mklib.save.SaveManager;
import mklib.state.State;

/**
 * Basisklasse für visuelle Entities, die aus einem LDtk-Level geladen werden.
 *
 * Erbt von `FlxSprite` und synchronisiert automatisch Position, Abmessungen,
 * die eindeutige Instanz-ID (`iid`), die Referenz auf den aktuellen `State`,
 * den Pfad zur zugewiesenen Grafikdatei (`graphicPath`) sowie das automatische
 * Zuschneiden von Tile-Ausschnitten (`TileRect`).
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
	 * Wenn in LDtk ein Single Value Tile mit dem Namen "TileRect" definiert und nicht `null` ist,
	 * wird der entsprechende Ausschnitt aus dem Tileset geladen und die Sprite-Größe angepasst.
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

		var tileRectField:Dynamic = getField("TileRect");
		if (tileRectField == null) {
			tileRectField = getField("tileRect");
		}

		var animKeyVal:Dynamic = getField("Animations");
		if (animKeyVal == null) {
			animKeyVal = getField("animations");
		}

		if (tileRectField != null) {
			var tilesetUid:Int = Reflect.hasField(tileRectField, "tilesetUid") ? Reflect.field(tileRectField, "tilesetUid") : 0;
			var tileX:Int = Reflect.hasField(tileRectField, "x") ? Reflect.field(tileRectField, "x") : 0;
			var tileY:Int = Reflect.hasField(tileRectField, "y") ? Reflect.field(tileRectField, "y") : 0;
			var tileW:Int = Reflect.hasField(tileRectField, "w") ? Reflect.field(tileRectField, "w") : (Reflect.hasField(tileRectField, "width") ? Reflect.field(tileRectField, "width") : Std.int(entity.width));
			var tileH:Int = Reflect.hasField(tileRectField, "h") ? Reflect.field(tileRectField, "h") : (Reflect.hasField(tileRectField, "height") ? Reflect.field(tileRectField, "height") : Std.int(entity.height));

			var resolvedPath:Null<String> = resolveTilesetPath(tilesetUid);
			if (resolvedPath != null) {
				graphicPath = resolvedPath;
				hasGraphic = true;
				loadTileRectGraphic(resolvedPath, tileX, tileY, tileW, tileH);
			} else {
				width = tileW;
				height = tileH;
			}
		} else {
			graphicPath = getGraphicPath();

			if (animKeyVal != null) {
				initAnimation(Std.string(animKeyVal));
			} else if (hasGraphic && _entity.tileInfos != null) {
				loadGraphic(graphicPath, true, _entity.tileInfos.w, _entity.tileInfos.h);
			}
		}

		if (animKeyVal != null && graphic == null) {
			initAnimation(Std.string(animKeyVal));
		}

		if (hasField("visible")) {
			visible = getField("visible");
		}

		if (hasField("alpha")) {
			alpha = getField("alpha");
		}
	}

	/**
	 * Liest den Wert eines benutzerdefinierten LDtk-Feldes (`fieldInstances`) aus.
	 *
	 * @param identifier Der Bezeichner des Feldes in LDtk (z. B. "image", "TileRect", "speed").
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
	 * Ermittelt und normalisiert den Pfad zur Tileset-Grafikdatei anhand der Tileset-UID aus dem LDtk-Projekt.
	 *
	 * @param tilesetUid Die UID des Tilesets im LDtk-Projekt.
	 * @return Der aufgelöste relative Asset-Pfad (z. B. "assets/tilesets/dungeon.png") oder `null`.
	 */
	public function resolveTilesetPath(tilesetUid:Int):Null<String> {
		if (_entity == null) {
			return null;
		}

		var proj:ldtk.Project = (state != null && state.project != null) ? state.project : @:privateAccess _entity.untypedProject;
		if (proj == null) {
			return null;
		}

		var tilesetDef = proj.getTilesetDefJson(tilesetUid);
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
		return normalized;
	}

	/**
	 * Schneidet einen spezifischen rechteckigen Ausschnitt aus einer Tilemap/Tileset-Grafik
	 * aus und weist ihn diesem Sprite zu.
	 *
	 * @param path Relativer Asset-Pfad zur Tileset-Grafikdatei.
	 * @param tileX X-Koordinate des Ausschnitts im Tileset (in Pixeln).
	 * @param tileY Y-Koordinate des Ausschnitts im Tileset (in Pixeln).
	 * @param tileW Breite des Ausschnitts (in Pixeln).
	 * @param tileH Höhe des Ausschnitts (in Pixeln).
	 */
	public function loadTileRectGraphic(path:String, tileX:Int, tileY:Int, tileW:Int, tileH:Int):Void {
		var cacheKey:String = path + "_tileRect_" + tileX + "_" + tileY + "_" + tileW + "_" + tileH;
		if (FlxG.bitmap != null && FlxG.bitmap.checkCache(cacheKey)) {
			loadGraphic(FlxG.bitmap.get(cacheKey));
		} else {
			var sourceBmd:openfl.display.BitmapData = null;
			if (FlxG.bitmap != null) {
				var sourceGraphic = FlxG.bitmap.add(path);
				if (sourceGraphic != null && sourceGraphic.bitmap != null) {
					sourceBmd = sourceGraphic.bitmap;
				}
			}
			if (sourceBmd == null && openfl.utils.Assets.exists(path)) {
				sourceBmd = openfl.utils.Assets.getBitmapData(path);
			}

			if (sourceBmd != null) {
				var cropBmd = new openfl.display.BitmapData(tileW, tileH, true, 0x00000000);
				cropBmd.copyPixels(sourceBmd, new openfl.geom.Rectangle(tileX, tileY, tileW, tileH), new openfl.geom.Point(0, 0));
				if (FlxG.bitmap != null) {
					var croppedGraphic = FlxG.bitmap.add(cropBmd, false, cacheKey);
					loadGraphic(croppedGraphic);
				} else {
					loadGraphic(cropBmd);
				}
			}
		}
		width = tileW;
		height = tileH;
	}

	/**
	 * Ermittelt und normalisiert den Pfad zur Grafikdatei (beginnend mit `assets/`),
	 * falls der Entity in LDtk ein Tile oder TileRect zugewiesen ist. Setzt zudem das Flag `hasGraphic`.
	 *
	 * @return Der aufgelöste Asset-Pfad zur Bilddatei oder `null`.
	 */
	public function getGraphicPath():Null<String> {
		hasGraphic = false;

		if (_entity == null) {
			return null;
		}

		var tileRect:Dynamic = getField("TileRect");
		if (tileRect == null) {
			tileRect = getField("tileRect");
		}
		if (tileRect != null) {
			var tilesetUid:Int = Reflect.hasField(tileRect, "tilesetUid") ? Reflect.field(tileRect, "tilesetUid") : 0;
			var path = resolveTilesetPath(tilesetUid);
			if (path != null) {
				hasGraphic = true;
				return path;
			}
		}

		var animField:Dynamic = getField("Animations");
		if (animField == null) {
			animField = getField("animations");
		}
		if (animField != null) {
			var animData = AnimationManager.get(Std.string(animField));
			if (animData != null && animData.imagePath != null) {
				hasGraphic = true;
				return animData.imagePath;
			}
		}

		if (_entity.tileInfos != null) {
			var path = resolveTilesetPath(_entity.tileInfos.tilesetUid);
			if (path != null) {
				hasGraphic = true;
				return path;
			}
		}

		return null;
	}

	/**
	 * Initialisiert und startet Animationen aus der `AnimationRegistry` bzw. den JSON-Dateien für diese Entity.
	 *
	 * @param animKey Name/Schlüssel der Animationsdefinition (z. B. "Hero", "Warg").
	 *                Falls nicht angegeben, wird das LDtk-Feld `"Animations"` bzw. `"animations"` verwendet.
	 */
	public function initAnimation(?animKey:String):Void {
		if (animKey == null) {
			var fieldVal:Dynamic = getField("Animations");
			if (fieldVal == null) {
				fieldVal = getField("animations");
			}
			if (fieldVal != null) {
				animKey = Std.string(fieldVal);
			}
		}
		if (animKey != null) {
			AnimationManager.apply(this, animKey, true);
			var animData = AnimationManager.get(animKey);
			if (animData != null && animData.imagePath != null) {
				graphicPath = animData.imagePath;
				hasGraphic = true;
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
