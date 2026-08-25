package mklib.path;

import flixel.math.FlxPoint;

/**
 * Repräsentiert eine diskrete 2D-Koordinate (X, Y) innerhalb eines Rasters (`NavGrid`).
 */
class GridPoint
{
	/**
	 * Die X-Koordinate im Grid (Spalte).
	 */
	public var x:Int;

	/**
	 * Die Y-Koordinate im Grid (Zeile).
	 */
	public var y:Int;

	/**
	 * Erstellt einen neuen Rasterpunkt.
	 *
	 * @param x Die X-Rasterkoordinate.
	 * @param y Die Y-Rasterkoordinate.
	 */
	public function new(x:Int, y:Int)
	{
		this.x = x;
		this.y = y;
	}

	/**
	 * Prüft, ob dieser Punkt identisch mit einem anderen `GridPoint` ist.
	 *
	 * @param other Der zu vergleichende Punkt.
	 * @return `true`, wenn beide Punkte dieselben Koordinaten besitzen, sonst `false`.
	 */
	public inline function equals(other:GridPoint):Bool
	{
		return other != null && this.x == other.x && this.y == other.y;
	}

	/**
	 * Gibt eine formatierte String-Darstellung im Format "(x, y)" zurück.
	 */
	public function toString():String
	{
		return '($x, $y)';
	}
}

/**
 * Interner Knoten für den A*-Suchgraphen.
 */
private class AStarNode
{
	/**
	 * Die X-Rasterkoordinate des Knotens.
	 */
	public var x:Int;

	/**
	 * Die Y-Rasterkoordinate des Knotens.
	 */
	public var y:Int;

	/**
	 * Der lineare 1D-Array-Index im `NavGrid`.
	 */
	public var index:Int;

	/**
	 * Die tatsächlichen Bewegungskosten vom Startknoten bis zu diesem Knoten (G-Score).
	 */
	public var g:Float = 0;

	/**
	 * Die geschätzten heuristischen Restkosten von diesem Knoten bis zum Ziel (H-Score).
	 */
	public var h:Float = 0;

	/**
	 * Die Gesamtkosten (F-Score = `g + h`).
	 */
	public var f:Float = 0;

	/**
	 * Der Vorgängerknoten im optimalen Pfad.
	 */
	public var parent:AStarNode = null;

	/**
	 * Gibt an, ob sich der Knoten aktuell in der Open-List befindet.
	 */
	public var inOpen:Bool = false;

	/**
	 * Gibt an, ob der Knoten bereits abschließend untersucht wurde (Closed-Set).
	 */
	public var inClosed:Bool = false;

	/**
	 * Erstellt einen neuen A*-Suchknoten.
	 *
	 * @param x Die X-Rasterkoordinate.
	 * @param y Die Y-Rasterkoordinate.
	 * @param index Der 1D-Index im Raster.
	 */
	public function new(x:Int, y:Int, index:Int)
	{
		this.x = x;
		this.y = y;
		this.index = index;
	}
}

/**
 * Performante A*-Pathfinding-Implementierung für NavGrid.
 * Unterstützt 4-Wege- und 8-Wege-Bewegung sowie Einheiten beliebiger Tile-Größe.
 */
class AStar
{
	/**
	 * Konstante für die Quadratwurzel aus 2 (ca. 1.4142) zur Berechnung diagonaler Schrittkosten.
	 */
	private static inline var SQRT2:Float = 1.41421356237;

	/**
	 * Findet den kürzesten Pfad in Grid-Koordinaten.
	 * 
	 * @param grid Das NavGrid
	 * @param startX Start-X im Grid
	 * @param startY Start-Y im Grid
	 * @param goalX Ziel-X im Grid
	 * @param goalY Ziel-Y im Grid
	 * @param agentSpanX Breite der Suchenden-Einheit in Grid-Zellen (Standard: 1)
	 * @param agentSpanY Höhe der Suchenden-Einheit in Grid-Zellen (Standard: 1)
	 * @param allowDiagonal Ob diagonale Bewegung erlaubt ist (Standard: false)
	 * @return Array von GridPoints vom Start zum Ziel (oder leeres Array, falls kein Weg existiert)
	 */
	public static function findPath(grid:NavGrid, startX:Int, startY:Int, goalX:Int, goalY:Int, agentSpanX:Int = 1, agentSpanY:Int = 1, allowDiagonal:Bool = false):Array<GridPoint>
	{
		if (grid == null)
		{
			return [];
		}

		// Ziel oder Start außerhalb der Map?
		if (!grid.isInBounds(startX, startY) || !grid.isInBounds(goalX, goalY))
		{
			return [];
		}

		// Wenn Start bereits Ziel ist
		if (startX == goalX && startY == goalY)
		{
			return [new GridPoint(startX, startY)];
		}

		// Kann das Ziel überhaupt betreten werden?
		if (!grid.isAreaWalkable(goalX, goalY, agentSpanX, agentSpanY))
		{
			return [];
		}

		var totalCells:Int = grid.width * grid.height;
		var nodes:Array<AStarNode> = [for (_ in 0...totalCells) null];
		var openList:Array<AStarNode> = [];

		var startIndex:Int = grid.getIndex(startX, startY);
		var startNode = new AStarNode(startX, startY, startIndex);
		startNode.h = heuristic(startX, startY, goalX, goalY, allowDiagonal);
		startNode.f = startNode.h;
		startNode.inOpen = true;

		nodes[startIndex] = startNode;
		openList.push(startNode);

		// Richtungsvektoren
		var dxList:Array<Int>;
		var dyList:Array<Int>;
		var costList:Array<Float>;

		if (allowDiagonal)
		{
			dxList = [0, 1, 0, -1, 1, 1, -1, -1];
			dyList = [-1, 0, 1, 0, -1, 1, 1, -1];
			costList = [1.0, 1.0, 1.0, 1.0, SQRT2, SQRT2, SQRT2, SQRT2];
		}
		else
		{
			dxList = [0, 1, 0, -1];
			dyList = [-1, 0, 1, 0];
			costList = [1.0, 1.0, 1.0, 1.0];
		}

		while (openList.length > 0)
		{
			// Finde Knoten mit geringstem F-Wert
			var bestIdx:Int = 0;
			var current:AStarNode = openList[0];
			for (i in 1...openList.length)
			{
				if (openList[i].f < current.f || (openList[i].f == current.f && openList[i].h < current.h))
				{
					current = openList[i];
					bestIdx = i;
				}
			}

			// Ziel erreicht?
			if (current.x == goalX && current.y == goalY)
			{
				return reconstructPath(current);
			}

			// Aus Open entfernen und in Closed verschieben
			openList.splice(bestIdx, 1);
			current.inOpen = false;
			current.inClosed = true;

			// Untersuche Nachbarn
			for (i in 0...dxList.length)
			{
				var nx:Int = current.x + dxList[i];
				var ny:Int = current.y + dyList[i];

				// Prüfe Begehbarkeit für die gesamte Agenten-Fläche
				if (!grid.isAreaWalkable(nx, ny, agentSpanX, agentSpanY))
				{
					continue;
				}

				// Bei Diagonalen: Kein Ecken-Schneiden bei Hindernissen
				if (allowDiagonal && i >= 4)
				{
					if (!grid.isAreaWalkable(current.x + dxList[i], current.y, agentSpanX, agentSpanY)
						|| !grid.isAreaWalkable(current.x, current.y + dyList[i], agentSpanX, agentSpanY))
					{
						continue;
					}
				}

				var nIndex:Int = grid.getIndex(nx, ny);
				var neighbor:AStarNode = nodes[nIndex];

				if (neighbor == null)
				{
					neighbor = new AStarNode(nx, ny, nIndex);
					nodes[nIndex] = neighbor;
				}

				if (neighbor.inClosed)
				{
					continue;
				}

				var tentativeG:Float = current.g + costList[i];

				if (!neighbor.inOpen)
				{
					neighbor.parent = current;
					neighbor.g = tentativeG;
					neighbor.h = heuristic(nx, ny, goalX, goalY, allowDiagonal);
					neighbor.f = neighbor.g + neighbor.h;
					neighbor.inOpen = true;
					openList.push(neighbor);
				}
				else if (tentativeG < neighbor.g)
				{
					neighbor.parent = current;
					neighbor.g = tentativeG;
					neighbor.f = neighbor.g + neighbor.h;
				}
			}
		}

		// Kein Pfad gefunden
		return [];
	}

	/**
	 * Findet den kürzesten Pfad und gibt ihn direkt als Flixel-Weltkoordinaten (`FlxPoint`) zurück.
	 *
	 * @param grid Das Navigationsraster.
	 * @param startWorldX Startposition X in Pixeln/Weltkoordinaten.
	 * @param startWorldY Startposition Y in Pixeln/Weltkoordinaten.
	 * @param goalWorldX Zielposition X in Pixeln/Weltkoordinaten.
	 * @param goalWorldY Zielposition Y in Pixeln/Weltkoordinaten.
	 * @param agentSpanX Breite der Einheit in Grid-Zellen (Standard: 1).
	 * @param agentSpanY Höhe der Einheit in Grid-Zellen (Standard: 1).
	 * @param allowDiagonal Ob diagonale Bewegungen erlaubt sind (Standard: false).
	 * @param centered Wenn `true`, zentriert die Rückgabepunkte im Mittelpunkt der Zelle (Standard: true).
	 * @return Ein Array von `FlxPoint`-Weltkoordinaten.
	 */
	public static function findWorldPath(grid:NavGrid, startWorldX:Float, startWorldY:Float, goalWorldX:Float, goalWorldY:Float,
			agentSpanX:Int = 1, agentSpanY:Int = 1, allowDiagonal:Bool = false, centered:Bool = true):Array<FlxPoint>
	{
		if (grid == null)
		{
			return [];
		}

		var startCx:Int = grid.worldToGridX(startWorldX);
		var startCy:Int = grid.worldToGridY(startWorldY);
		var goalCx:Int = grid.worldToGridX(goalWorldX);
		var goalCy:Int = grid.worldToGridY(goalWorldY);

		var gridPath:Array<GridPoint> = findPath(grid, startCx, startCy, goalCx, goalCy, agentSpanX, agentSpanY, allowDiagonal);
		var worldPath:Array<FlxPoint> = [];

		for (p in gridPath)
		{
			worldPath.push(FlxPoint.get(grid.gridToWorldX(p.x, centered), grid.gridToWorldY(p.y, centered)));
		}

		return worldPath;
	}

	/**
	 * Berechnet den heuristischen Distanzwert zwischen zwei Rasterpunkten.
	 *
	 * Verwendet Manhattan-Distanz für 4-Wege-Bewegung und Octile-Distanz für 8-Wege-Bewegung.
	 *
	 * @param x1 Start-X.
	 * @param y1 Start-Y.
	 * @param x2 Ziel-X.
	 * @param y2 Ziel-Y.
	 * @param allowDiagonal Ob diagonale Pfadsuche aktiviert ist.
	 * @return Die geschätzten Kosten bis zum Ziel.
	 */
	private static inline function heuristic(x1:Int, y1:Int, x2:Int, y2:Int, allowDiagonal:Bool):Float
	{
		var dx:Float = Math.abs(x1 - x2);
		var dy:Float = Math.abs(y1 - y2);

		if (!allowDiagonal)
		{
			return dx + dy; // Manhattan Distance
		}
		else
		{
			// Octile Distance
			return (dx > dy) ? (SQRT2 * dy + (dx - dy)) : (SQRT2 * dx + (dy - dx));
		}
	}

	/**
	 * Rekonstruiert den Pfad rückwärts vom Zielknoten bis zum Startknoten.
	 *
	 * @param node Der erreichte Zielknoten.
	 * @return Eine geordnete Liste von `GridPoint` vom Start bis zum Ziel.
	 */
	private static function reconstructPath(node:AStarNode):Array<GridPoint>
	{
		var path:Array<GridPoint> = [];
		var curr:AStarNode = node;

		while (curr != null)
		{
			path.unshift(new GridPoint(curr.x, curr.y));
			curr = curr.parent;
		}

		return path;
	}
}
