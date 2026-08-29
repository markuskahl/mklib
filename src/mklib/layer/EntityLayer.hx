package mklib.layer;

import ldtk.Entity;
import mklib.state.State;
import mklib.entity.EntitySprite;
import mklib.entity.EntityNapeSprite;
import mklib.save.SaveManager;
import mklib.save.ISaveable;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxG;

/**
 * Struktureller Typ für LDtk-Entity-Layer-Quellen.
 */
typedef EntityLayerSource<T = Dynamic> = {
	/**
	 * Der Layer-Bezeichner (z. B. "Entities", "Interactive").
	 */
	var identifier:String;

	/**
	 * Gibt alle Entities des Layers als typunabhängiges Array zurück.
	 */
	function getAllUntyped():Array<T>;
}

/**
 * Verwaltet und instanziiert automatisch alle Entities eines LDtk-Layers als HaxeFlixel-Sprites.
 *
 * Durchsucht zur Laufzeit via Reflection das angegebene Package (Standard: `"entities"`) nach Klassen,
 * deren Name dem Entity-Identifier in LDtk entspricht (z. B. Entity `Hero` -> `entities.Hero`).
 * Falls keine spezifische Klasse definiert ist, wird automatisch eine passende Instanz von
 * `EntityNapeSprite` (bei vorhandener Nape-Physik/Tags/Feldern) oder `EntitySprite` erzeugt.
 */
class EntityLayer extends FlxSpriteGroup {
	/**
	 * Der Bezeichner des LDtk-Layers.
	 */
	public var layerName:String;

	/**
	 * Das Haxe-Package, in dem nach passenden Entity-Klassen gesucht wird (z. B. "entities").
	 */
	public var packageName:String;

	/**
	 * Referenz auf den aktuellen `mklib.state.State`.
	 */
	public var state:State<Dynamic>;

	/**
	 * Erstellt einen neuen EntityLayer und instanziiert automatisch alle enthaltenen Entities.
	 *
	 * @param layer Die LDtk-Entity-Layer-Quelle (z. B. `data.l_Entities`).
	 * @param packageName Das Package mit den Entity-Klassendefinitionen (Standard: `"entities"`).
	 */
	public function new(layer:EntityLayerSource<Dynamic>, packageName:String = "entities") {
		super();
		this.packageName = packageName;
		if (FlxG.state != null && Std.isOfType(FlxG.state, State)) {
			state = cast(FlxG.state, State);
		}

		if (layer != null) {
			this.layerName = layer.identifier;
			var untypedList:Array<Dynamic> = layer.getAllUntyped();
			if (untypedList != null) {
				var entityList:Array<ldtk.Entity> = [for (e in untypedList) cast e];
				addEntities(entityList);
			}
		}
	}

	/**
	 * Instanziiert dynamisch passende Klassen für die übergebenen LDtk-Entities und fügt sie dieser Gruppe hinzu.
	 *
	 * Existiert eine spezifische Klasse im Ziel-Package (z. B. `entities.Hero`), wird diese instanziiert.
	 * Andernfalls wird geprüft, ob die Entity als `EntityNapeSprite` (Physik) oder `EntitySprite`
	 * instanziiert werden soll.
	 *
	 * @param entities Ein Array von LDtk-Entity-Objekten.
	 */
	public function addEntities(entities:Array<ldtk.Entity>):Void {
		if (entities == null) {
			return;
		}

		var activeLevelName:Null<String> = (state != null) ? state.levelName : null;

		for (i in 0...entities.length) {
			var entity:ldtk.Entity = entities[i];

			// Prüfe, ob die Entity im Save-Zustand bereits als zerstört markiert ist
			if (entity.iid != null && SaveManager.isEntityDestroyed(entity.iid, activeLevelName)) {
				continue;
			}

			var entityName:String = entity.identifier;
			packageName = "entities.";

			var createdSprite:Null<FlxSprite> = null;
			var targetClass:String = packageName + entityName;
			var cls = Type.resolveClass(targetClass);
			if (cls != null) {
				var o:Dynamic = Type.createInstance(cls, [entity]);
				if (Std.isOfType(o, EntitySprite) || Std.isOfType(o, EntityNapeSprite)) {
					createdSprite = cast o;
					add(createdSprite);
				}
			} else {
				if (isNapeEntity(entity)) {
					createdSprite = new EntityNapeSprite(entity);
					add(createdSprite);
				} else {
					createdSprite = new EntitySprite(entity);
					add(createdSprite);
				}
			}

			// Stellt eventuell vorhandene ISaveable-Zustandsdaten für diese Entity wieder her
			if (createdSprite != null && Std.isOfType(createdSprite, ISaveable)) {
				SaveManager.restoreEntity(createdSprite, activeLevelName);
			}
		}
	}

	/**
	 * Prüft, ob eine LDtk-Entity ein benutzerdefiniertes Feld "Tag" besitzt.
	 *
	 * @param entity Die zu prüfende LDtk-Entity.
	 * @return `true`, wenn das Feld "Tag" vorhanden und nicht `null` ist, andernfalls `false`.
	 */
	public function hasTag(entity:ldtk.Entity):Bool {
		if (entity != null && entity.json != null && entity.json.fieldInstances != null) {
			for (inst in entity.json.fieldInstances) {
				if (inst.__identifier == "Tag" && inst.__value != null) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Kompatibilitäts-Alias für `hasTag`.
	 */
	public inline function isNapeEntity(entity:ldtk.Entity):Bool {
		return hasTag(entity);
	}
}
