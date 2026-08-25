package mklib.path;

import ldtk.Entity;
import ldtk.Layer;
import ldtk.Layer_Entities;
import ldtk.Layer_IntGrid;
import ldtk.Layer_Tiles;
import ldtk.Layer_AutoLayer;

/**
 * Fluent Builder zum komfortablen Zusammenführen beliebiger LDtk-Layer (IntGrid, Tiles, AutoLayers, Entities)
 * in ein einheitliches `NavGrid` für Pathfinding (z. B. A*).
 */
class NavGridBuilder
{
	/**
	 * Das aktuell aufgebaute `NavGrid`.
	 */
	public var grid(default, null):NavGrid;

	/**
	 * Das zugrundeliegende LDtk-Level-Objekt (falls per `fromLevel` initialisiert).
	 */
	private var level:Dynamic;

	/**
	 * Erstellt einen neuen `NavGridBuilder` mit expliziten Abmessungen.
	 *
	 * @param width Breite in Grid-Zellen.
	 * @param height Höhe in Grid-Zellen.
	 * @param gridSize Kantenlänge einer Zelle in Pixeln (Standard: 16).
	 * @param defaultValue Standardwert für freie Zellen (Standard: 0).
	 */
	public function new(width:Int, height:Int, gridSize:Int = 16, defaultValue:Int = 0)
	{
		grid = new NavGrid(width, height, gridSize, defaultValue);
	}

	/**
	 * Erstellt einen neuen Builder anhand eines LDtk-Level-Objekts (z. B. `data.l_Level_0`).
	 * Liest automatisch `cWid`, `cHei` und `gridSize` aus dem Level aus.
	 *
	 * @param levelObj Das LDtk-Level-Objekt.
	 * @param defaultGridSize Fallback-Kantenlänge in Pixeln (Standard: 16).
	 * @return Eine neue `NavGridBuilder`-Instanz.
	 */
	public static function fromLevel(levelObj:Dynamic, defaultGridSize:Int = 16):NavGridBuilder
	{
		var cWid:Int = 1;
		var cHei:Int = 1;
		var gSize:Int = defaultGridSize;

		if (levelObj != null)
		{
			if (Reflect.hasField(levelObj, "cWid"))
			{
				cWid = Reflect.field(levelObj, "cWid");
			}
			if (Reflect.hasField(levelObj, "cHei"))
			{
				cHei = Reflect.field(levelObj, "cHei");
			}
			if (Reflect.hasField(levelObj, "gridSize"))
			{
				gSize = Reflect.field(levelObj, "gridSize");
			}
			else if (Reflect.hasField(levelObj, "pxWid") && cWid > 0)
			{
				var pxWid:Int = Reflect.field(levelObj, "pxWid");
				gSize = Std.int(pxWid / cWid);
			}
		}

		var builder = new NavGridBuilder(cWid, cHei, gSize);
		builder.level = levelObj;
		return builder;
	}

	/**
	 * Fügt ein IntGrid-Layer als Hindernis hinzu.
	 *
	 * @param layer Das LDtk-IntGrid-Layer-Objekt.
	 * @param isSolid Optionales Prädikat: Gibt zurück, ob ein gegebener IntGrid-Wert als solide/blockiert gilt.
	 *                (Standard: Jeder Wert `!= 0` gilt als blockiert).
	 * @return Der Builder für Methodenverkettung (Fluent Interface).
	 */
	public function addIntGrid(layer:Dynamic, ?isSolid:(value:Int) -> Bool):NavGridBuilder
	{
		if (layer == null)
		{
			return this;
		}

		for (cy in 0...grid.height)
		{
			for (cx in 0...grid.width)
			{
				if (Reflect.hasField(layer, "getInt") || Reflect.isFunction(Reflect.field(layer, "getInt")))
				{
					var val:Int = cast layer.getInt(cx, cy);
					var solid = isSolid != null ? isSolid(val) : (val != 0);
					if (solid)
					{
						grid.set(cx, cy, 1);
					}
				}
				else if (Reflect.hasField(layer, "hasValue") || Reflect.isFunction(Reflect.field(layer, "hasValue")))
				{
					if (cast layer.hasValue(cx, cy))
					{
						grid.set(cx, cy, 1);
					}
				}
			}
		}
		return this;
	}

	/**
	 * Fügt ein Tile- oder AutoLayer-Layer als Hindernis hinzu.
	 *
	 * @param layer Das LDtk-Tile- oder AutoLayer-Objekt.
	 * @param isSolid Optionales Prädikat zur Filterung nach `tileId`.
	 *                (Standard: Jedes vorhandene Tile gilt als blockiert).
	 * @return Der Builder für Methodenverkettung (Fluent Interface).
	 */
	public function addTileLayer(layer:Dynamic, ?isSolid:(tileId:Int) -> Bool):NavGridBuilder
	{
		if (layer == null)
		{
			return this;
		}

		for (cy in 0...grid.height)
		{
			for (cx in 0...grid.width)
			{
				if (Reflect.hasField(layer, "hasAnyTileAt") && Reflect.isFunction(Reflect.field(layer, "hasAnyTileAt")))
				{
					if (cast layer.hasAnyTileAt(cx, cy))
					{
						if (isSolid != null && Reflect.hasField(layer, "getTile"))
						{
							var tile:Dynamic = layer.getTile(cx, cy);
							var tileId:Int = (tile != null && Reflect.hasField(tile, "tileId")) ? Reflect.field(tile, "tileId") : 0;
							if (isSolid(tileId))
							{
								grid.set(cx, cy, 1);
							}
						}
						else
						{
							grid.set(cx, cy, 1);
						}
					}
				}
			}
		}
		return this;
	}

	/**
	 * Fügt ein Entity-Layer hinzu und blockiert die von Entities belegten Rasterzellen.
	 *
	 * @param layer Das LDtk-Entity-Layer-Objekt oder ein Array von Entities.
	 * @param filter Optionales Prädikat: Bestimmt, ob eine Entity als Hindernis blockieren soll (Standard: alle).
	 * @return Der Builder für Methodenverkettung (Fluent Interface).
	 */
	public function addEntityLayer(layer:Dynamic, ?filter:(entity:ldtk.Entity) -> Bool):NavGridBuilder
	{
		if (layer == null)
		{
			return this;
		}

		var entities:Array<Dynamic> = null;
		if (Reflect.hasField(layer, "getAllUntyped") && Reflect.isFunction(Reflect.field(layer, "getAllUntyped")))
		{
			entities = layer.getAllUntyped();
		}
		else if (Std.isOfType(layer, Array))
		{
			entities = cast layer;
		}

		if (entities != null)
		{
			for (e in entities)
			{
				var entity:ldtk.Entity = cast e;
				if (entity != null)
				{
					var shouldAdd:Bool = (filter != null) ? filter(entity) : true;
					if (shouldAdd)
					{
						grid.setEntity(entity, 1);
					}
				}
			}
		}

		return this;
	}

	/**
	 * Löst einen Layer anhand seines Namens aus dem übergebenen Level auf und fügt ihn dem Raster hinzu.
	 * Erkennt automatisch, ob es sich um IntGrid, Tiles/AutoLayer oder Entities handelt.
	 *
	 * @param layerName Der Name des Layers im Level (z. B. "Collisions", "SolidEntities").
	 * @param isSolidEntity Optionales Prädikat für Entities.
	 * @return Der Builder für Methodenverkettung (Fluent Interface).
	 */
	public function addLayerByName(layerName:String, ?isSolidEntity:(entity:ldtk.Entity) -> Bool):NavGridBuilder
	{
		if (level == null || layerName == null)
		{
			return this;
		}

		var layer:Dynamic = null;
		if (Reflect.hasField(level, "resolveLayer") && Reflect.isFunction(Reflect.field(level, "resolveLayer")))
		{
			layer = level.resolveLayer(layerName);
		}
		else if (Reflect.hasField(level, layerName))
		{
			layer = Reflect.field(level, layerName);
		}

		if (layer != null)
		{
			if (Std.isOfType(layer, Layer_IntGrid))
			{
				addIntGrid(layer);
			}
			else if (Std.isOfType(layer, Layer_Tiles) || Std.isOfType(layer, Layer_AutoLayer))
			{
				addTileLayer(layer);
			}
			else if (Std.isOfType(layer, Layer_Entities) || Reflect.hasField(layer, "getAllUntyped"))
			{
				addEntityLayer(layer, isSolidEntity);
			}
		}

		return this;
	}

	/**
	 * Scannt automatisch alle bekannten Layer eines LDtk-Levels und baut das fertige `NavGrid`.
	 *
	 * @param levelObj Das LDtk-Level-Objekt (z. B. `data`).
	 * @param isSolidEntity Optionaler Filter für solide Entities.
	 * @param defaultGridSize Fallback-Kantenlänge in Pixeln (Standard: 16).
	 * @return Das fertig zusammengestellte `NavGrid`.
	 */
	public static function autoBuild(levelObj:Dynamic, ?isSolidEntity:(entity:ldtk.Entity) -> Bool, defaultGridSize:Int = 16):NavGrid
	{
		var builder = fromLevel(levelObj, defaultGridSize);
		if (levelObj == null)
		{
			return builder.grid;
		}

		// Durchsuche alle Felder des Level-Objekts nach Layern
		var fields:Array<String> = Reflect.fields(levelObj);
		for (field in fields)
		{
			var val:Dynamic = Reflect.field(levelObj, field);
			if (val != null)
			{
				if (Std.isOfType(val, Layer_IntGrid))
				{
					builder.addIntGrid(val);
				}
				else if (Std.isOfType(val, Layer_Tiles) || Std.isOfType(val, Layer_AutoLayer))
				{
					builder.addTileLayer(val);
				}
				else if (Std.isOfType(val, Layer_Entities) || (Reflect.hasField(val, "getAllUntyped") && Reflect.isFunction(Reflect.field(val, "getAllUntyped"))))
				{
					builder.addEntityLayer(val, isSolidEntity);
				}
			}
		}

		return builder.build();
	}

	/**
	 * Schließt die Konfiguration ab und liefert die fertige `NavGrid`-Instanz zurück.
	 *
	 * @return Das konfigurierte `NavGrid`.
	 */
	public function build():NavGrid
	{
		return grid;
	}
}
