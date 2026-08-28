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
- [**Animationssystem & Makros (`AnimationBuilder` & `AnimationTypes`)**](docs/animation.md)
- [**Physik & Sensoren (`Listener` & `Tags`)**](docs/physics.md)
- [**Pathfinding & Navigation (`NavGrid`, `NavGridBuilder`, `AStar`)**](docs/pathfinding.md)
- [**GPU-Lighting-System (`LightingSystem`, `Light`, `PointLight`, `SpotLight`, `TorchLight`, `GlowLight`)**](docs/lighting.md)
- [**Tools & Mathematik (`AspectRatio` & `MathTool`)**](docs/tools_math.md)

---

## 🏛️ Vollständige API-Übersicht

| Modul | Klasse / Typ | Eigenschaften | Methoden |
| :--- | :--- | :--- | :--- |
| `mklib.state` | `State<TLevel>` | `project`, `tags`, `levelName`, `data` | `new`, `create`, `addCbTypes`, `napeInit`, `update` |
| `mklib.layer` | `TileLayer` | `levelName`, `layerName`, `state` | `new`, `render` |
| `mklib.layer` | `EntityLayer` | `layerName`, `packageName`, `state` | `new`, `addEntities`, `isNapeEntity` |
| `mklib.layer` | `EntityLayerSource<T>` | `identifier`, `getAllUntyped` | – |
| `mklib.entity` | `EntitySprite` | `_entity`, `iid`, `state`, `graphicPath`, `hasGraphic` | `new`, `getGraphicPath`, `getField`, `hasField`, `initAnimation` |
| `mklib.entity` | `EntityNapeSprite` | `_entity`, `iid`, `state`, `graphicPath`, `hasGraphic`, `body` | `new`, `getGraphicPath`, `getField`, `hasField`, `sensorEnabled`, `addCbType`, `updateShapePosition`, `initAnimation` |
| `mklib.light` | `LightingSystem` | `lights`, `ambientColor`, `ambientIntensity`, `autoCull`, `shadowsEnabled`, `shadowSteps`, `shadowSoftness`, `occluders`, `shaderInstance` | `new`, `addLight`, `removeLight`, `clearLights`, `addOccluder`, `addOccluders`, `addOccluderClass`, `removeOccluder`, `removeOccluderClass`, `clearOccluders`, `createPointLight`, `createSpotLight`, `createTorchLight`, `createGlowLight`, `createDirectionalLight`, `loadFromLevel`, `loadFromEntityLayer`, `fromEntity` |
| `mklib.light` | `Light` | `x`, `y`, `radius`, `color`, `intensity`, `falloff`, `active`, `visible`, `target` | `new`, `follow`, `stopFollowing`, `setPosition`, `setColor`, `update`, `destroy` |
| `mklib.light` | `PointLight` | `innerRadius` | `new` |
| `mklib.light` | `SpotLight` | `angle`, `spotAngle`, `innerAngle` | `new`, `pointAt`, `lookAt` |
| `mklib.light` | `TorchLight` | `flickerSpeed`, `flickerIntensity`, `flickerRadius`, `flameJitter` | `new`, `update` |
| `mklib.light` | `GlowLight` | `minRadius`, `maxRadius`, `minIntensity`, `maxIntensity`, `pulseSpeed` | `new`, `update` |
| `mklib.light` | `DirectionalLight` | `directionAngle` | `new` |
| `mklib.animation` | `FrameConfig` | `width`, `height`, `spacing`, `margin` | – |
| `mklib.animation` | `AnimationClip` | `name`, `fps`, `loop`, `flipX`, `flipY`, `frames` | – |
| `mklib.animation` | `SpriteSheetData` | `imagePath`, `config`, `animations`, `defaultAnimation` | – |
| `mklib.macro` | `AnimationBuilder` | – | `buildDatabase` |
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
import mklib.light.LightingSystem;
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

        // 5. GPU-Shader-Beleuchtung mit LDtk-Entities laden
        var lighting = new LightingSystem(0xFF141424, 0.2);
        lighting.loadFromLevel(data);
        add(lighting);
    }
}
```

---

## 📄 Lizenz

MIT License. Siehe [haxelib.json](haxelib.json).