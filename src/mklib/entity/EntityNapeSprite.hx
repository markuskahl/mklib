package mklib.entity;

import nape.geom.Vec2;
import mklib.tools.Tags;
import mklib.state.State;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;

/**
 * Erweiterte Entity-Klasse mit integriertem Nape-Physikkörper (`FlxNapeSprite`).
 *
 * Ermöglicht das automatische Auslesen von Tags/Kollisionstypen (`CbType`) direkt aus den
 * LDtk-Feldern (`Tag` oder `Tags`), den Zugriff auf den Grafikpfad (`graphicPath`) sowie
 * die exakte Zentrierung von Nape-Shapes auf Basis der LDtk-Entity-Maße.
 */
class EntityNapeSprite extends FlxNapeSprite {
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
	 * Erstellt eine neue Instanz von `EntityNapeSprite` anhand einer LDtk-Entity.
	 *
	 * @param entity Die aus dem LDtk-Level geladene Entity-Definition.
	 */
	public function new(entity:ldtk.Entity) {
		iid = entity.iid;
		_entity = entity;
		super(entity.pixelX, entity.pixelY);

		if (FlxG.state != null && Std.isOfType(FlxG.state, State)) {
			state = cast FlxG.state;
		}

		graphicPath = getGraphicPath();

		if (hasGraphic) {
			loadGraphic(graphicPath, true, _entity.tileInfos.w, _entity.tileInfos.h);
		}
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
	 * Weist dem Nape-Physikkörper (`body`) die entsprechenden `CbType`-Tags zu.
	 *
	 * - Wird `name` übergeben, wird gezielt dieser Tag hinzugefügt.
	 * - Bleibt `name` leer (`null`), werden die Entity-Felder `Tag` bzw. `Tags` aus den LDtk-JSON-Daten
	 *   ausgewertet und alle übereinstimmenden CbTypes registriert.
	 *
	 * Zudem wird `body.userData.instance` auf diese Instanz gesetzt.
	 *
	 * @param name Optionaler Name des spezifischen Tags (Standard: `null`, automatisches Auslesen).
	 */
	public function addCbType(name:String = null):Void {
		if (body == null) {
			trace("Warning: Cannot add CbType because body is not yet initialized!");
			return;
		}

		if (name == null) {
			if (_entity != null && _entity.json != null && _entity.json.fieldInstances != null) {
				for (inst in _entity.json.fieldInstances) {
					if (inst.__identifier == "Tag" || inst.__identifier == "Tags") {
						if (Std.isOfType(inst.__value, Array)) {
							var arr:Array<Dynamic> = cast inst.__value;
							for (val in arr) {
								var tagStr:String = Std.string(val);
								if (Tags.exist(tagStr)) {
									body.cbTypes.add(Tags.get(tagStr));
								}
							}
						} else {
							var tagStr:String = Std.string(inst.__value);
							if (Tags.exist(tagStr)) {
								body.cbTypes.add(Tags.get(tagStr));
							}
						}
					}
				}
			}
		} else {
			if (Tags.exist(name)) {
				body.cbTypes.add(Tags.get(name));
			}
		}

		body.userData.instance = this;
	}

	/**
	 * Positioniert den Nape-Körper im Mittelpunkt der LDtk-Entity-Dimensionen.
	 * Hilfreich nach dem Erstellen von Nape-Shapes, da Nape-Körper standardmäßig
	 * ihren Ursprung im Schwerpunkt/Mittelpunkt haben.
	 */
	public function updateShapePosition():Void {
		if (body != null && _entity != null) {
			body.position.setxy(_entity.pixelX + (_entity.width / 2), _entity.pixelY + (_entity.height / 2));
		}
	}
}
