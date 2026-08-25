# mklib

**`mklib`** ist eine flexible Haxe-Bibliothek zur Verbindung von **HaxeFlixel**, **LDtk** und **Nape Physics**. Sie optimiert die Spieleentwicklung durch automatisches Laden von LDtk-Layern und -Entities, ein string-basiertes Nape-Kollisionssystem sowie schnelles 2D A*-Pathfinding mit Multi-Tile-Support.

---

## 📖 Dokumentation & Interaktive Website

Die vollständige interaktive Dokumentation inklusive Live-A*-Pathfinding-Simulator findest du unter:
👉 **[`docs/index.html`](docs/index.html)** (im Browser öffnen oder über GitHub Pages)

### Einzelkapitel:
- [**Schnellstart & Einrichtung**](docs/getting_started.md)
- [**State-Management (`mklib.state.State`)**](docs/state.md)
- [**Layer-System (`TileLayer` & `EntityLayer`)**](docs/layers.md)
- [**Entities & Spielobjekte (`EntitySprite` & `EntityNapeSprite`)**](docs/entities.md)
- [**Physik & Sensoren (`Listener` & `Tags`)**](docs/physics.md)
- [**Pathfinding & Navigation (`NavGrid`, `NavGridBuilder`, `AStar`)**](docs/pathfinding.md)
- [**Tools & Mathematik (`AspectRatio` & `MathTool`)**](docs/tools_math.md)

---

## 🏛️ Vollständige API-Übersicht

| Modul | Klasse / Typ | Eigenschaften | Methoden |
| :--- | :--- | :--- | :--- |
| `mklib.state` | `State<TLevel>` | `project`, `tags`, `levelName`, `data` | `new`, `create`, `addCbTypes`, `napeInit`, `update` |
| `mklib.layer` | `TileLayer` | `levelName`, `layerName`, `state` | `new`, `render` |
| `mklib.layer` | `EntityLayer` | `layerName`, `packageName`, `state` | `new`, `addEntities` |
| `mklib.layer` | `EntityLayerSource<T>` | `identifier`, `getAllUntyped` | – |
| `mklib.entity` | `EntitySprite` | `_entity`, `iid`, `state`, `graphicPath`, `hasGraphic` | `new`, `getGraphicPath` |
| `mklib.entity` | `EntityNapeSprite` | `_entity`, `iid`, `state`, `graphicPath`, `hasGraphic`, `body` | `new`, `getGraphicPath`, `addCbType`, `updateShapePosition` |
| `mklib.physic` | `Listener` | – | `addCollisionBeginListener`, `addCollisionEndListener`, `addCollisionOngoingListener`, `addSensorBeginListener`, `addSensorEndListener`, `addSensorOngoingListener`, `addSensorBeginListenerANY`, `addSensorEndListenerANY`, `addSensorOngoingListenerANY` |
| `mklib.tools` | `Tags` | – | `get`, `exist` |
| `mklib.path` | `NavGrid` | `width`, `height`, `gridSize`, `data` | `new`, `isInBounds`, `getIndex`, `get`, `set`, `isWalkable`, `isAreaWalkable`, `setArea`, `setEntity`, `worldToGridX`, `worldToGridY`, `gridToWorldX`, `gridToWorldY`, `clear`, `clone`, `toString` |
| `mklib.path` | `NavGridBuilder` | `grid`, `level` | `new`, `fromLevel`, `addIntGrid`, `addTileLayer`, `addEntityLayer`, `addLayerByName`, `autoBuild`, `build` |
| `mklib.path` | `AStar` | `SQRT2` | `findPath`, `findWorldPath`, `heuristic`, `reconstructPath` |
| `mklib.path` | `GridPoint` | `x`, `y` | `new`, `equals`, `toString` |
| `mklib.tools` | `AspectRatio` | `width`, `height`, `isDefault`, `screenRatio` | `new`, `calc`, `isInRange` |
| `mklib.math` | `MathTool` | – | `floatFix` |

---

## 🚀 Schnelleinstieg

```haxe
package;

import flixel.FlxG;
import mklib.state.State;
import mklib.layer.TileLayer;
import mklib.layer.EntityLayer;
import mklib.path.NavGridBuilder;
import mklib.path.NavGrid;

class PlayState extends State<Data.Data_Level> {
    override public function create():Void {
        super.create();

        // 1. Nape-Physik mit Schwerkraft initialisieren
        napeInit(0, 300);

        // 2. Kachelebene rendern
        add(new TileLayer(data.l_Tiles.identifier));

        // 3. Entities aus "entities.*" instanziieren
        add(new EntityLayer(data.l_Entities));

        // 4. A*-NavGrid automatisch aus Leveldaten bauen
        var navGrid:NavGrid = NavGridBuilder.autoBuild(data);
    }
}
```

---

## 📄 Lizenz

MIT License. Siehe [haxelib.json](haxelib.json).