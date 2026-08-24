package mklib.path;

import ldtk.Entity;

/**
 * Performantes 1D-Navigationsraster für Pathfinding (z. B. A*).
 * 0 = frei / begehbar
 * 1 = blockiert / Wand / Hindernis
 */
class NavGrid
{
	public var width(default, null):Int;
	public var height(default, null):Int;
	public var gridSize(default, null):Int;
	public var data:Array<Int>;

	public function new(width:Int, height:Int, gridSize:Int = 16, defaultValue:Int = 0)
	{
		this.width = width;
		this.height = height;
		this.gridSize = gridSize > 0 ? gridSize : 16;
		this.data = [for (_ in 0...(width * height)) defaultValue];
	}

	/**
	 * Prüft, ob sich die Grid-Koordinaten innerhalb der Map befinden.
	 */
	public inline function isInBounds(cx:Int, cy:Int):Bool
	{
		return cx >= 0 && cx < width && cy >= 0 && cy < height;
	}

	/**
	 * Berechnet den 1D-Array-Index aus (cx, cy).
	 */
	public inline function getIndex(cx:Int, cy:Int):Int
	{
		return (cy * width) + cx;
	}

	/**
	 * Gibt den Wert der Zelle zurück (oder 1 = blockiert, falls außerhalb der Map).
	 */
	public inline function get(cx:Int, cy:Int):Int
	{
		if (!isInBounds(cx, cy))
		{
			return 1;
		}
		return data[getIndex(cx, cy)];
	}

	/**
	 * Setzt den Wert einer Zelle.
	 */
	public inline function set(cx:Int, cy:Int, value:Int):Void
	{
		if (isInBounds(cx, cy))
		{
			data[getIndex(cx, cy)] = value;
		}
	}

	/**
	 * Prüft, ob eine einzelne Zelle begehbar ist (Wert == 0).
	 */
	public inline function isWalkable(cx:Int, cy:Int):Bool
	{
		return isInBounds(cx, cy) && data[getIndex(cx, cy)] == 0;
	}

	/**
	 * Prüft, ob ein Bereich der Größe (spanX * spanY) frei ist.
	 * Ideal für Charaktere / Einheiten, die größer als ein einzelnes Tile sind (z. B. 2x2).
	 */
	public function isAreaWalkable(cx:Int, cy:Int, spanX:Int = 1, spanY:Int = 1):Bool
	{
		if (cx < 0 || cy < 0 || (cx + spanX) > width || (cy + spanY) > height)
		{
			return false;
		}

		for (dy in 0...spanY)
		{
			for (dx in 0...spanX)
			{
				if (data[getIndex(cx + dx, cy + dy)] != 0)
				{
					return false;
				}
			}
		}

		return true;
	}

	/**
	 * Markiert einen rechteckigen Bereich im Grid mit einem Wert (z. B. 1 für blockiert).
	 */
	public function setArea(cx:Int, cy:Int, spanX:Int, spanY:Int, value:Int = 1):Void
	{
		for (dy in 0...spanY)
		{
			for (dx in 0...spanX)
			{
				set(cx + dx, cy + dy, value);
			}
		}
	}

	/**
	 * Markiert die Fläche eines LDtk-Entities im Grid.
	 * Berechnet die Spanne in Grid-Zellen anhand von entity.width und entity.height.
	 */
	public function setEntity(entity:ldtk.Entity, value:Int = 1):Void
	{
		if (entity == null)
		{
			return;
		}

		var spanX:Int = Std.int(Math.max(1, Math.ceil(entity.width / gridSize)));
		var spanY:Int = Std.int(Math.max(1, Math.ceil(entity.height / gridSize)));

		setArea(entity.cx, entity.cy, spanX, spanY, value);
	}

	/**
	 * Konvertiert Pixel-/Weltkoordinate X in Gridkoordinate cx.
	 */
	public inline function worldToGridX(worldX:Float):Int
	{
		return Math.floor(worldX / gridSize);
	}

	/**
	 * Konvertiert Pixel-/Weltkoordinate Y in Gridkoordinate cy.
	 */
	public inline function worldToGridY(worldY:Float):Int
	{
		return Math.floor(worldY / gridSize);
	}

	/**
	 * Konvertiert Gridkoordinate cx in Pixel-/Weltkoordinate X.
	 */
	public inline function gridToWorldX(cx:Int, centered:Bool = false):Float
	{
		return (cx * gridSize) + (centered ? (gridSize * 0.5) : 0);
	}

	/**
	 * Konvertiert Gridkoordinate cy in Pixel-/Weltkoordinate Y.
	 */
	public inline function gridToWorldY(cy:Int, centered:Bool = false):Float
	{
		return (cy * gridSize) + (centered ? (gridSize * 0.5) : 0);
	}

	/**
	 * Setzt alle Zellen auf den angegebenen Wert zurück.
	 */
	public function clear(value:Int = 0):Void
	{
		for (i in 0...data.length)
		{
			data[i] = value;
		}
	}

	/**
	 * Erstellt eine tiefe Kopie des Grids.
	 */
	public function clone():NavGrid
	{
		var copy = new NavGrid(width, height, gridSize);
		copy.data = this.data.copy();
		return copy;
	}

	/**
	 * Gibt eine ASCII-Vorschau des Grids für Debugging-Zwecke zurück.
	 */
	public function toString():String
	{
		var buf = new StringBuf();
		for (cy in 0...height)
		{
			for (cx in 0...width)
			{
				buf.add(data[getIndex(cx, cy)] == 0 ? "." : "#");
			}
			buf.add("\n");
		}
		return buf.toString();
	}
}
