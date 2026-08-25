package mklib.path;

import ldtk.Entity;

/**
 * Performantes 2D-Navigationsraster auf Basis eines flachen 1D-Arrays für Pathfinding (z. B. A*).
 *
 * Konvention:
 * - `0` = frei / begehbar
 * - `1` (oder > 0) = blockiert / Wand / Hindernis
 */
class NavGrid
{
	/**
	 * Die Breite des Grids in Zellen (Spalten).
	 */
	public var width(default, null):Int;

	/**
	 * Die Höhe des Grids in Zellen (Zeilen).
	 */
	public var height(default, null):Int;

	/**
	 * Die Kantenlänge einer Grid-Zelle in Pixeln (z. B. 16 für 16x16 Pixel).
	 */
	public var gridSize(default, null):Int;

	/**
	 * Das flache 1D-Array mit den Zellwerten. Größe = `width * height`.
	 */
	public var data:Array<Int>;

	/**
	 * Erstellt ein neues Navigationsraster.
	 *
	 * @param width Die Breite in Grid-Zellen.
	 * @param height Die Höhe in Grid-Zellen.
	 * @param gridSize Die Kantenlänge einer Zelle in Pixeln (Standard: 16).
	 * @param defaultValue Der Anfangswert aller Zellen (Standard: 0 = frei).
	 */
	public function new(width:Int, height:Int, gridSize:Int = 16, defaultValue:Int = 0)
	{
		this.width = width;
		this.height = height;
		this.gridSize = gridSize > 0 ? gridSize : 16;
		this.data = [for (_ in 0...(width * height)) defaultValue];
	}

	/**
	 * Prüft, ob sich die übergebenen Rasterkoordinaten innerhalb der Rastergrenzen befinden.
	 *
	 * @param cx Raster-X (Spalte).
	 * @param cy Raster-Y (Zeile).
	 * @return `true`, wenn sich (cx, cy) innerhalb des Grids befindet, sonst `false`.
	 */
	public inline function isInBounds(cx:Int, cy:Int):Bool
	{
		return cx >= 0 && cx < width && cy >= 0 && cy < height;
	}

	/**
	 * Berechnet den linearen 1D-Array-Index aus zweidimensionalen Rasterkoordinaten.
	 *
	 * Formel: `(cy * width) + cx`
	 *
	 * @param cx Raster-X.
	 * @param cy Raster-Y.
	 * @return Der Index im `data`-Array.
	 */
	public inline function getIndex(cx:Int, cy:Int):Int
	{
		return (cy * width) + cx;
	}

	/**
	 * Gibt den Wert der Zelle an den Koordinaten (cx, cy) zurück.
	 * Liegt der Punkt außerhalb der Grenzen, wird `1` (blockiert) zurückgegeben.
	 *
	 * @param cx Raster-X.
	 * @param cy Raster-Y.
	 * @return Der Zellwert (`0` für frei, `1` für blockiert).
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
	 * Setzt den Wert einer bestimmten Rasterzelle.
	 *
	 * @param cx Raster-X.
	 * @param cy Raster-Y.
	 * @param value Der neue Wert (`0` = frei, `1` = blockiert).
	 */
	public inline function set(cx:Int, cy:Int, value:Int):Void
	{
		if (isInBounds(cx, cy))
		{
			data[getIndex(cx, cy)] = value;
		}
	}

	/**
	 * Prüft, ob eine einzelne Zelle begehbar ist (befindet sich im Raster und Wert == 0).
	 *
	 * @param cx Raster-X.
	 * @param cy Raster-Y.
	 * @return `true`, wenn die Zelle frei und begehbar ist.
	 */
	public inline function isWalkable(cx:Int, cy:Int):Bool
	{
		return isInBounds(cx, cy) && data[getIndex(cx, cy)] == 0;
	}

	/**
	 * Prüft, ob ein zusammenhängender rechteckiger Bereich der Größe (`spanX` * `spanY`) frei ist.
	 * Ideal für Einheiten oder Charaktere, die größer als ein einzelnes Tile sind (z. B. 2x2 Zellen).
	 *
	 * @param cx Start-Raster-X (obere linke Ecke).
	 * @param cy Start-Raster-Y (obere linke Ecke).
	 * @param spanX Breite des Bereichs in Zellen (Standard: 1).
	 * @param spanY Höhe des Bereichs in Zellen (Standard: 1).
	 * @return `true`, wenn alle Zellen des Bereichs frei (`0`) und innerhalb des Rasters sind.
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
	 * Markiert einen rechteckigen Bereich im Raster mit einem bestimmten Wert.
	 *
	 * @param cx Start-Raster-X (obere linke Ecke).
	 * @param cy Start-Raster-Y (obere linke Ecke).
	 * @param spanX Breite des Bereichs in Zellen.
	 * @param spanY Höhe des Bereichs in Zellen.
	 * @param value Der zu setzende Wert (Standard: 1 = blockiert).
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
	 * Markiert die Fläche einer LDtk-Entity im Raster als blockiert oder frei.
	 * Die Zellspanne wird automatisch anhand von `entity.width` und `entity.height` berechnet.
	 *
	 * @param entity Die LDtk-Entity.
	 * @param value Der zu setzende Wert (Standard: 1 = blockiert).
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
	 * Rechnet eine Pixel-/Weltkoordinate X in eine Rasterkoordinate `cx` um.
	 *
	 * @param worldX Die X-Koordinate in Pixeln.
	 * @return Die entsprechende Spalte im Raster.
	 */
	public inline function worldToGridX(worldX:Float):Int
	{
		return Math.floor(worldX / gridSize);
	}

	/**
	 * Rechnet eine Pixel-/Weltkoordinate Y in eine Rasterkoordinate `cy` um.
	 *
	 * @param worldY Die Y-Koordinate in Pixeln.
	 * @return Die entsprechende Zeile im Raster.
	 */
	public inline function worldToGridY(worldY:Float):Int
	{
		return Math.floor(worldY / gridSize);
	}

	/**
	 * Rechnet eine Rasterkoordinate `cx` in eine Pixel-/Weltkoordinate X um.
	 *
	 * @param cx Die Rasterspalte.
	 * @param centered Wenn `true`, wird die Pixelmitte der Zelle zurückgegeben (`+ gridSize * 0.5`).
	 * @return Die X-Koordinate in Pixeln.
	 */
	public inline function gridToWorldX(cx:Int, centered:Bool = false):Float
	{
		return (cx * gridSize) + (centered ? (gridSize * 0.5) : 0);
	}

	/**
	 * Rechnet eine Rasterkoordinate `cy` in eine Pixel-/Weltkoordinate Y um.
	 *
	 * @param cy Die Rasterzeile.
	 * @param centered Wenn `true`, wird die Pixelmitte der Zelle zurückgegeben (`+ gridSize * 0.5`).
	 * @return Die Y-Koordinate in Pixeln.
	 */
	public inline function gridToWorldY(cy:Int, centered:Bool = false):Float
	{
		return (cy * gridSize) + (centered ? (gridSize * 0.5) : 0);
	}

	/**
	 * Setzt alle Zellen des gesamten Rasters auf den angegebenen Wert zurück.
	 *
	 * @param value Der Wert, auf den alle Zellen gesetzt werden (Standard: 0 = frei).
	 */
	public function clear(value:Int = 0):Void
	{
		for (i in 0...data.length)
		{
			data[i] = value;
		}
	}

	/**
	 * Erstellt eine vollständige Kopie (Deep Copy) dieses Navigationsrasters.
	 *
	 * @return Eine neue unabhängige `NavGrid`-Instanz mit identischen Daten.
	 */
	public function clone():NavGrid
	{
		var copy = new NavGrid(width, height, gridSize);
		copy.data = this.data.copy();
		return copy;
	}

	/**
	 * Erzeugt eine ASCII-Darstellung des Rasters für Logging- und Debugging-Zwecke.
	 * (`.` = frei, `#` = blockiert).
	 *
	 * @return Die gerenderte Zeichenkette.
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
