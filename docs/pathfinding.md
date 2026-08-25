# Pathfinding & Navigation (`mklib.path.*`)

Das Pathfinding-Modul von `mklib` bietet eine vollständige, speichereffiziente 2D A*-Wegfindung für Tilemaps und Level. Es unterstützt Multi-Tile-Einheiten beliebiger Größe, 4- und 8-Wege-Bewegung (mit Ecken-Schutz) sowie das automatische Erzeugen des Navigationsrasters aus beliebigen LDtk-Layern.

---

## 🗺️ `NavGrid` (`mklib.path.NavGrid`)

Speichert die Begehbarkeit der Spielwelt in einem schnellen, flachen 1D-Array (`width * height`).
- `0` = frei / begehbar
- `1` (oder `> 0`) = blockiert / Wand / Hindernis

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `width` | `Int` | `public (default, null)` | Die Breite des Rasters in Grid-Zellen (Spalten). Schreibgeschützt von außen. |
| `height` | `Int` | `public (default, null)` | Die Höhe des Rasters in Grid-Zellen (Zeilen). Schreibgeschützt von außen. |
| `gridSize` | `Int` | `public (default, null)` | Die Kantenlänge einer Zelle in Pixeln (z. B. `16` für 16x16 Pixel). |
| `data` | `Array<Int>` | `public` | Das flache 1D-Array der Größe `width * height` mit allen Zellwerten. |

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(width:Int, height:Int, gridSize:Int = 16, defaultValue:Int = 0)` | `Void` | Erstellt ein neues Navigationsraster mit den angegebenen Maßen und initialisiert alle Zellen mit `defaultValue`. |
| `isInBounds` | `(cx:Int, cy:Int)` | `Bool` | Prüft, ob die Rasterkoordinaten `(cx, cy)` innerhalb des Grids liegen (`0 <= cx < width` und `0 <= cy < height`). |
| `getIndex` | `(cx:Int, cy:Int)` | `Int` | Berechnet den 1D-Array-Index aus 2D-Rasterkoordinaten: `(cy * width) + cx`. |
| `get` | `(cx:Int, cy:Int)` | `Int` | Gibt den Wert der Zelle an `(cx, cy)` zurück. Liegt der Punkt außerhalb der Grenzen, wird `1` (blockiert) zurückgegeben. |
| `set` | `(cx:Int, cy:Int, value:Int)` | `Void` | Setzt den Wert der Zelle an `(cx, cy)`, sofern innerhalb der Grenzen. |
| `isWalkable` | `(cx:Int, cy:Int)` | `Bool` | Prüft, ob eine einzelne Zelle begehbar ist (`isInBounds(cx, cy)` und `get(cx, cy) == 0`). |
| `isAreaWalkable` | `(cx:Int, cy:Int, spanX:Int = 1, spanY:Int = 1)` | `Bool` | Prüft, ob ein zusammenhängender rechteckiger Bereich der Größe `spanX * spanY` ab `(cx, cy)` komplett frei (`0`) und innerhalb des Rasters ist. Ideal für Multi-Tile-Einheiten (z. B. 2x2). |
| `setArea` | `(cx:Int, cy:Int, spanX:Int, spanY:Int, value:Int = 1)` | `Void` | Markiert einen rechteckigen Bereich der Größe `spanX * spanY` mit `value`. |
| `setEntity` | `(entity:ldtk.Entity, value:Int = 1)` | `Void` | Blockiert die Rasterfläche einer LDtk-Entity. Die Zellspanne wird automatisch über `ceil(entity.width / gridSize)` und `ceil(entity.height / gridSize)` ermittelt. |
| `worldToGridX` | `(worldX:Float)` | `Int` | Rechnet eine Pixel-/Weltkoordinate X in eine Rasterspalte um: `floor(worldX / gridSize)`. |
| `worldToGridY` | `(worldY:Float)` | `Int` | Rechnet eine Pixel-/Weltkoordinate Y in eine Rasterzeile um: `floor(worldY / gridSize)`. |
| `gridToWorldX` | `(cx:Int, centered:Bool = false)` | `Float` | Rechnet eine Rasterspalte `cx` in eine Pixel-X-Koordinate um. Bei `centered == true` wird die Zelle zentriert (`+ gridSize * 0.5`). |
| `gridToWorldY` | `(cy:Int, centered:Bool = false)` | `Float` | Rechnet eine Rasterzeile `cy` in eine Pixel-Y-Koordinate um. Bei `centered == true` wird die Zelle zentriert (`+ gridSize * 0.5`). |
| `clear` | `(value:Int = 0)` | `Void` | Setzt alle Zellen des gesamten Rasters auf `value` zurück. |
| `clone` | `()` | `NavGrid` | Erstellt eine vollständige, unabhängige Kopie (Deep Copy) des Navigationsrasters. |
| `toString` | `()` | `String` | Erzeugt eine ASCII-Darstellung des Rasters für Debugging und Logging (`.` = frei, `#` = blockiert). |

---

## 🔨 `NavGridBuilder` (`mklib.path.NavGridBuilder`)

Fluent Builder zum komfortablen Zusammenführen beliebiger LDtk-Layer (IntGrid, Tiles, AutoLayers, Entities) in ein einheitliches `NavGrid`.

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `grid` | `NavGrid` | `public (default, null)` | Das aktuell vom Builder verwaltete `NavGrid`. |
| `level` | `Dynamic` | `private` | Das zugrundeliegende LDtk-Level-Objekt (bei Initialisierung via `fromLevel`). |

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(width:Int, height:Int, gridSize:Int = 16, defaultValue:Int = 0)` | `Void` | Erstellt einen neuen `NavGridBuilder` mit expliziten Abmessungen. |
| `fromLevel` | `(levelObj:Dynamic, defaultGridSize:Int = 16)` | `NavGridBuilder` | *(Statisch)* Erstellt einen Builder anhand eines LDtk-Level-Objekts und liest automatisch `cWid`, `cHei` und `gridSize` aus. |
| `addIntGrid` | `(layer:Dynamic, ?isSolid:(value:Int)->Bool)` | `NavGridBuilder` | Fügt ein IntGrid-Layer als Hindernis hinzu. Standardmäßig gilt jeder Wert `!= 0` als solide. |
| `addTileLayer` | `(layer:Dynamic, ?isSolid:(tileId:Int)->Bool)` | `NavGridBuilder` | Fügt ein Tile- oder AutoLayer-Layer hinzu. Standardmäßig blockiert jedes vorhandene Tile. |
| `addEntityLayer` | `(layer:Dynamic, ?filter:(entity:ldtk.Entity)->Bool)` | `NavGridBuilder` | Fügt ein Entity-Layer hinzu und blockiert die von den Entities belegten Rasterzellen. |
| `addLayerByName` | `(layerName:String, ?isSolidEntity:(entity:ldtk.Entity)->Bool)` | `NavGridBuilder` | Löst einen Layer anhand seines Namens aus dem Level auf und erkennt automatisch den Layertyp (IntGrid, Tiles, Entities). |
| `autoBuild` | `(levelObj:Dynamic, ?isSolidEntity:(entity:ldtk.Entity)->Bool, defaultGridSize:Int = 16)` | `NavGrid` | *(Statisch)* Scannt automatisch alle bekannten Felder/Layer eines LDtk-Levels und baut das fertige `NavGrid` in einem Schritt. |
| `build` | `()` | `NavGrid` | Schließt den Builder ab und liefert die fertige `NavGrid`-Instanz zurück. |

---

## 🧭 `AStar` & `GridPoint` (`mklib.path.AStar`, `mklib.path.GridPoint`)

### `GridPoint`
Repräsentiert eine diskrete 2D-Koordinate (X, Y) im Grid.

| Eigenschaft / Methode | Signatur / Typ | Beschreibung |
| :--- | :--- | :--- |
| `x` | `Int` *(Eigenschaft)* | Die X-Rasterkoordinate (Spalte). |
| `y` | `Int` *(Eigenschaft)* | Die Y-Rasterkoordinate (Zeile). |
| `new` | `(x:Int, y:Int)` *(Methode)* | Erstellt einen neuen `GridPoint`. |
| `equals` | `(other:GridPoint):Bool` *(Methode)* | Prüft zwei Punkte auf Koordinatengleichheit. |
| `toString` | `():String` *(Methode)* | Gibt `(x, y)` als formatierte Zeichenkette zurück. |

### `AStar`
Implementiert die optimierte A*-Wegfindung mit Open-/Closed-Listen und Richtungskosten.

| Element | Signatur / Typ | Beschreibung |
| :--- | :--- | :--- |
| `SQRT2` | `Float = 1.41421356237` *(Konstante)* | Schrittkosten für diagonale Schritte. |
| `findPath` | `(grid:NavGrid, startX:Int, startY:Int, goalX:Int, goalY:Int, agentSpanX:Int = 1, agentSpanY:Int = 1, allowDiagonal:Bool = false):Array<GridPoint>` | Berechnet den kürzesten Pfad im Grid. Liefert ein Array von `GridPoint` vom Start bis zum Ziel. |
| `findWorldPath` | `(grid:NavGrid, startWorldX:Float, startWorldY:Float, goalWorldX:Float, goalWorldY:Float, agentSpanX:Int = 1, agentSpanY:Int = 1, allowDiagonal:Bool = false, centered:Bool = true):Array<flixel.math.FlxPoint>` | Rechnet Weltkoordinaten automatisch in Gridkoordinaten um, führt die Pfadsuche durch und gibt das Ergebnis direkt als Array von `FlxPoint`-Weltkoordinaten zurück. |

---

## 💡 Code-Beispiele

### 1. Raster vollautomatisch aus Level generieren

```haxe
// Alle IntGrid-, Tile- und Entity-Layer automatisch scannen:
var navGrid = NavGridBuilder.autoBuild(data);
```

### 2. Gegner steuern mit `findWorldPath`

```haxe
package entities;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import mklib.path.AStar;
import mklib.path.NavGrid;
import ldtk.Entity;

class Enemy extends FlxSprite {
    public var path:Array<FlxPoint> = [];
    public var navGrid:NavGrid;

    public function new(entity:ldtk.Entity, grid:NavGrid) {
        super(entity.pixelX, entity.pixelY);
        this.navGrid = grid;
        makeGraphic(16, 16, 0xFFFF0000);
    }

    /**
     * Berechnet den Pfad zum Spieler in Weltkoordinaten (8-Wege-Bewegung).
     */
    public function moveTo(targetWorldX:Float, targetWorldY:Float):Void {
        // Pfadsuche mit Diagonalen (allowDiagonal = true) und zentrierten Wegpunkten
        path = AStar.findWorldPath(navGrid, x, y, targetWorldX, targetWorldY, 1, 1, true, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        // Nächsten Wegpunkt ansteuern:
        if (path.length > 0) {
            var target = path[0];
            var dx = target.x - (x + width / 2);
            var dy = target.y - (y + height / 2);
            var dist = Math.sqrt(dx * dx + dy * dy);

            if (dist < 4) {
                target.put(); // FlxPoint recyclen
                path.shift();
            } else {
                velocity.set((dx / dist) * 80, (dy / dist) * 80);
            }
        } else {
            velocity.set(0, 0);
        }
    }
}
```
