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

## 📦 Features im Überblick

- **LDtk-Integration**: Kachelebenen (`TileLayer`) und automatische Entity-Instanziierung (`EntityLayer`) via Reflection.
- **Nape-Physik**: Einfache Kollisions- und Sensor-Listener (`Listener.addCollisionBeginListener`, `Listener.addSensorBeginListener`) über Tag-Namen.
- **Pathfinding**: A*-Wegfindung für 4- und 8-Wege-Bewegung mit automatischer Rastererstellung (`NavGridBuilder.autoBuild`) und Einheiten beliebiger Kachelgröße (`spanX` / `spanY`).
- **Responsive Resolution**: Automatische Berechnung optimaler Auflösungen für Breitbild-Displays (`AspectRatio`).

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