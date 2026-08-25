package mklib.layer;

import ldtk.Entity;
import mklib.state.State;
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
 */
class EntityLayer extends FlxSpriteGroup
{
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
	public function new(layer:EntityLayerSource<Dynamic>, packageName:String = "entities")
	{
		super();
		this.packageName = packageName;
		if (FlxG.state != null && Std.isOfType(FlxG.state, State))
		{
			state = cast(FlxG.state, State);
		}

		if (layer != null)
		{
			this.layerName = layer.identifier;
			var untypedList:Array<Dynamic> = layer.getAllUntyped();
			if (untypedList != null)
			{
				var entityList:Array<ldtk.Entity> = [for (e in untypedList) cast e];
				addEntities(entityList);
			}
		}
	}

	/**
	 * Instanziiert dynamisch passende Klassen für die übergebenen LDtk-Entities und fügt sie dieser Gruppe hinzu.
	 *
	 * @param entities Ein Array von LDtk-Entity-Objekten.
	 */
	public function addEntities(entities:Array<ldtk.Entity>):Void
	{
		if (entities == null)
		{
			return;
		}

		for (i in 0...entities.length)
		{
			var entity:ldtk.Entity = entities[i];
			var entityName:String = entity.identifier;

			var targetClass:String = (packageName != null && packageName.length > 0) ? (packageName + "." + entityName) : entityName;
			var cls = Type.resolveClass(targetClass);
			if (cls != null)
			{
				var o:Dynamic = Type.createInstance(cls, [entity]);
				if (Std.isOfType(o, FlxSprite))
				{
					add(cast o);
				}
			}
			else
			{
				trace('Error: Class "' + targetClass + '" does not exist!');
			}
		}
	}
}
