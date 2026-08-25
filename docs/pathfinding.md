# Pathfinding & Navigation (`mklib.path.*`)

Das Pathfinding-Modul von `mklib` bietet eine vollständige, speichereffiziente A*-Wegfindung für 2D-Tilemaps. Es unterstützt Multi-Tile-Einheiten beliebiger Größe, 4- und 8-Wege-Bewegung sowie das automatische Erzeugen des Navigationsrasters aus LDtk-Leveln.

---

## 🗺️ `NavGrid` (Navigationsraster)

`mklib.path.NavGrid` speichert die Begehbarkeit der Spielwelt in einem schnellen, flachen 1D-Array (`width * height`).

- `0` = frei / begehbar
- `1` (oder `> 0`) = blockiert / Wand / Hindernis

### Wichtige Methoden

| Methode | Beschreibung |
| :--- | :--- |
| `isWalkable(cx, cy)` | Prüft, ob eine einzelne Zelle begehbar ist. |
| `isAreaWalkable(cx, cy, spanX, spanY)` | Prüft, ob ein ganzer Bereich (z. B. 2x2 Zellen für große Einheiten) frei ist. |
| `set(cx, cy, value)` | Setzt den Wert einer Zelle (`0` = frei, `1` = blockiert). |
| `setArea(cx, cy, spanX, spanY, value)` | Blockiert einen rechteckigen Bereich. |
| `setEntity(entity, value)` | Blockiert die Kacheln einer LDtk-Entity anhand ihrer Pixelmaße. |
| `worldToGridX(x)` / `worldToGridY(y)` | Rechnet Pixel-Weltkoordinaten in Rasterkoordinaten um. |
| `gridToWorldX(cx, centered)` / `gridToWorldY(cy, centered)` | Rechnet Rasterkoordinaten in Pixel-Weltkoordinaten um. |

---

## 🔨 `NavGridBuilder` (Raster aus LDtk erzeugen)

Der `NavGridBuilder` scannt deine LDtk-Level und wandelt IntGrid-, Tile-, AutoLayer- und Entity-Ebenen automatisch in ein `NavGrid` um.

### 1. Vollautomatischer Aufbau (`autoBuild`)

```haxe
// Erstellt das NavGrid automatisch aus allen Layern des Levels:
var navGrid = NavGridBuilder.autoBuild(data);
```

Optional mit Filter für solide Entities:

```haxe
var navGrid = NavGridBuilder.autoBuild(data, function(entity) {
    // Nur Entities mit dem Bezeichner "Wall" oder "Rock" blockieren das Grid
    return entity.identifier == "Wall" || entity.identifier == "Rock";
});
```

### 2. Manueller Aufbau mit Fluent-Interface

```haxe
var navGrid = NavGridBuilder.fromLevel(data)
    .addIntGrid(data.l_Collisions, (val) -> val == 1) // Nur IntGrid-Wert 1 ist solide
    .addTileLayer(data.l_Tiles)                      // Alle platzierten Tiles blockieren
    .addEntityLayer(data.l_Entities, (e) -> e.identifier != "Coin") // Münzen blockieren nicht
    .build();
```

---

## 🧭 `AStar` (Pfadsuche)

Die Klasse `mklib.path.AStar` führt die A*-Wegfindung durch.

### API-Methoden

#### 1. In Rasterkoordinaten (`findPath`)

```haxe
public static function findPath(
    grid:NavGrid,
    startX:Int, startY:Int,
    goalX:Int, goalY:Int,
    agentSpanX:Int = 1, agentSpanY:Int = 1,
    allowDiagonal:Bool = false
):Array<GridPoint>;
```

#### 2. In Pixel-/Weltkoordinaten (`findWorldPath`)

```haxe
public static function findWorldPath(
    grid:NavGrid,
    startWorldX:Float, startWorldY:Float,
    goalWorldX:Float, goalWorldY:Float,
    agentSpanX:Int = 1, agentSpanY:Int = 1,
    allowDiagonal:Bool = false,
    centered:Bool = true
):Array<flixel.math.FlxPoint>;
```

---

## 💡 Code-Beispiel: Gegner-Navigation mit Wegpunkten

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
     * Berechnet den Weg zum Spieler in Pixel-Weltkoordinaten (8-Wege-Bewegung).
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
