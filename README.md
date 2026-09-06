# mklib

**`mklib`** is a flexible and lightweight Haxe library designed to seamlessly connect **HaxeFlixel**, **LDtk**, and **Nape Physics**. It accelerates 2D game development through automated loading of LDtk layers and entities, an intuitive string-based Nape collision tag system, GPU-accelerated lighting, water reflection shaders, and fast 2D A* pathfinding with multi-tile support.

---

## 📖 Documentation & Interactive Website

The complete interactive documentation, including a live A* pathfinding simulator, is available at:  
👉 **[`docs/html/index.html`](docs/html/index.html)** (open in your browser or view via GitHub Pages)

### Documentation Chapters:
- [**Getting Started & Setup**](docs/md/getting_started.md)
- [**State Management (`mklib.state.State`)**](docs/md/state.md)
- [**Layer System (`TileLayer` & `EntityLayer`)**](docs/md/layers.md)
- [**Entities & Game Objects (`EntitySprite` & `EntityNapeSprite`)**](docs/md/entities.md)
- [**Save & Persistence System (`SaveManager` & `ISaveable`)**](docs/md/save.md)
- [**Animation System & Macros (`AnimationBuilder` & `AnimationTypes`)**](docs/md/animation.md)
- [**Physics & Sensors (`Listener` & `Tags`)**](docs/md/physics.md)
- [**Pathfinding & Navigation (`NavGrid`, `NavGridBuilder`, `AStar`)**](docs/md/pathfinding.md)
- [**GPU Lighting System (`LightingSystem`, `Light`, `PointLight`, `SpotLight`, `TorchLight`, `GlowLight`)**](docs/md/lighting.md)
- [**Shader & Post-Processing System (`CrtShader`, `HazardLiquid*`, `WaterReflection*`)**](docs/md/shaders.md)
- [**Tools & Math Utilities (`AspectRatio`, `GamepadHelper` & `MathTool`)**](docs/md/tools_math.md)

---

## 🧩 Complete API Overview

| Module | Class / Type | Properties | Methods |
| :--- | :--- | :--- | :--- |
| `mklib.state` | `State<TLevel>` | `project`, `tags`, `levelName`, `data`, `autoPersistLevel` | `new`, `create`, `addCbTypes`, `napeInit`, `update`, `destroy` |
| `mklib.save` | `SaveManager` | `config`, `playTime`, `globals`, `levelStates`, `lastCheckpointMeta`, `onSave`, `onLoad` | `update`, `saveCheckpoint`, `loadCheckpoint`, `hasCheckpoint`, `clearCheckpoint`, `getCheckpointMeta`, `getLevelState`, `captureLevel`, `restoreLevel`, `clearSession`, `markEntityDestroyed`, `isEntityDestroyed`, `setEntityData`, `getEntityData`, `captureEntity`, `restoreEntity`, `setGlobal`, `getGlobal`, `hasGlobal`, `removeGlobal`, `clearGlobals`, `obfuscateString`, `deobfuscateString` |
| `mklib.save` | `ISaveable` |  | `saveState`, `loadState` |
| `mklib.save` | `CheckpointMeta` / `SaveProfile` | `timestamp`, `dateFormatted`, `playTimeSeconds`, `levelName`, `customMeta` |  |
| `mklib.layer` | `TileLayer` | `levelName`, `layerName`, `state` | `new`, `render` |
| `mklib.layer` | `EntityLayer` | `layerName`, `packageName`, `state` | `new`, `addEntities`, `isNapeEntity` |
| `mklib.layer` | `EntityLayerSource<T>` | `identifier`, `getAllUntyped` |  |
| `mklib.entity` | `EntitySprite` | `_entity`, `iid`, `state`, `graphicPath`, `hasGraphic` | `new`, `resolveTilesetPath`, `loadTileRectGraphic`, `getGraphicPath`, `getField`, `hasField`, `initAnimation`, `markDestroyed`, `isSaveDestroyed` |
| `mklib.entity` | `EntityNapeSprite` | `_entity`, `iid`, `state`, `graphicPath`, `hasGraphic`, `body` | `new`, `resolveTilesetPath`, `loadTileRectGraphic`, `getGraphicPath`, `getField`, `hasField`, `sensorEnabled`, `addCbType`, `updateShapePosition`, `initAnimation`, `markDestroyed`, `isSaveDestroyed` |
| `mklib.light` | `LightingSystem` | `lights`, `ambientColor`, `ambientIntensity`, `autoCull`, `shadowsEnabled`, `shadowSteps`, `shadowSoftness`, `occluders`, `shaderInstance` | `new`, `addLight`, `removeLight`, `clearLights`, `addOccluder`, `addOccluders`, `addOccluderClass`, `removeOccluder`, `removeOccluderClass`, `clearOccluders`, `createPointLight`, `createSpotLight`, `createTorchLight`, `createGlowLight`, `createDirectionalLight`, `loadFromLevel`, `loadFromEntityLayer`, `fromEntity` |
| `mklib.light` | `Light` | `x`, `y`, `radius`, `color`, `intensity`, `falloff`, `active`, `visible`, `target` | `new`, `follow`, `stopFollowing`, `setPosition`, `setColor`, `update`, `destroy` |
| `mklib.light` | `PointLight` | `innerRadius` | `new` |
| `mklib.light` | `SpotLight` | `angle`, `spotAngle`, `innerAngle` | `new`, `pointAt`, `lookAt` |
| `mklib.light` | `TorchLight` | `flickerSpeed`, `flickerIntensity`, `flickerRadius`, `flameJitter` | `new`, `update` |
| `mklib.light` | `GlowLight` | `minRadius`, `maxRadius`, `minIntensity`, `maxIntensity`, `pulseSpeed` | `new`, `update` |
| `mklib.light` | `DirectionalLight` | `directionAngle` | `new` |
| `mklib.effect` | `CrtShader` | `totalTime`, `filter` | `new`, `update`, `setCurvature`, `setScanlines`, `setRgbMask`, `setChromaticAberration`, `setVignette`, `setBloom`, `setAnalogNoise`, `presetSubtle`, `presetArcade`, `presetVhsGlitch` |
| `mklib.effect` | `HazardLiquidShader` | `totalTime` | `new`, `update`, `setColors`, `setFlowAndTurbulence`, `setSurfaceWave`, `setBubbles`, `setCrustThresholds`, `presetLava`, `presetAcid`, `presetToxic`, `applyType` |
| `mklib.effect` | `HazardLiquidPlane` | `shaderInstance`, `liquidType`, `damagePerSecond`, `isHazardous`, `autoUpdateShader` | `new`, `update`, `resizePlane`, `isOverlapping`, `applyHazardDamage` |
| `mklib.effect` | `HazardLiquidType` | `LAVA`, `ACID_SLIME`, `TOXIC_WATER`, `CUSTOM` |  |
| `mklib.effect` | `WaterReflectionShader` | `data` | `new`, `update`, `setWaterLevel`, `syncWithCamera`, `setWaveParams`, `setWaterColor`, `setFoam`, `setFade`, `setMode` |
| `mklib.effect` | `WaterReflectionPlane` | `shaderInstance`, `autoSyncCamera`, `targetCamera` | `new`, `update`, `setWaveParams`, `setFoam`, `destroy` |
| `mklib.effect` | `EntityWaterReflection` | `target`, `shaderInstance`, `offsetX`, `offsetY`, `verticalScale` | `new`, `update`, `syncWithTarget`, `setWaveParams`, `destroy` |
| `mklib.effect` | `WaterReflectionMode` | `VERTICAL_WATER_PLANE`, `HORIZONTAL_MIRROR`, `WAVE_DISTORTION_ONLY` |  |
| `mklib.animation` | `FrameConfig` | `width`, `height`, `spacing`, `margin` |  |
| `mklib.animation` | `AnimationClip` | `name`, `fps`, `loop`, `flipX`, `flipY`, `frames` |  |
| `mklib.animation` | `SpriteSheetData` | `imagePath`, `config`, `animations`, `defaultAnimation` |  |
| `mklib.animation` | `AnimationManager` |  | `apply`, `applyData`, `get`, `exists` |
| `mklib.macro` | `AnimationBuilder` |  | `buildDatabase` |
| `mklib.physic` | `Listener` |  | `addCollisionBeginListener`, `addCollisionEndListener`, `addCollisionOngoingListener`, `addSensorBeginListener`, `addSensorEndListener`, `addSensorOngoingListener`, `addSensorBeginListenerANY`, `addSensorEndListenerANY`, `addSensorOngoingListenerANY` |
| `mklib.tools` | `Tags` |  | `get`, `exist` |
| `mklib.path` | `NavGrid` | `width`, `height`, `gridSize`, `data` | `new`, `isInBounds`, `getIndex`, `get`, `set`, `isWalkable`, `isAreaWalkable`, `setArea`, `setEntity`, `worldToGridX`, `worldToGridY`, `gridToWorldX`, `gridToWorldY`, `clear`, `clone`, `toString` |
| `mklib.path` | `NavGridBuilder` | `grid`, `level` | `new`, `fromLevel`, `addIntGrid`, `addTileLayer`, `addEntityLayer`, `addLayerByName`, `autoBuild`, `build` |
| `mklib.path` | `AStar` | `SQRT2` | `findPath`, `findWorldPath`, `heuristic`, `reconstructPath` |
| `mklib.path` | `GridPoint` | `x`, `y` | `new`, `equals`, `toString` |
| `mklib.tools` | `AspectRatio` | `width`, `height`, `isDefault`, `screenRatio` | `new`, `calc`, `isInRange` |
| `mklib.tools` | `GamepadHelper` |  | `vibrate`, `rumble`, `stopVibration`, `vibrateAll`, `stopAllVibrations`, `getLimeGamepad` |
| `mklib.math` | `MathTool` |  | `floatFix` |

---

## 🚀 Quick Start

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

        // 1. Initialize Nape physics with downward gravity
        napeInit(0, 300);

        // 2. Render LDtk tile layer
        add(new TileLayer(data.l_Tiles.identifier));

        // 3. Instantiate entities from the "entities.*" package
        add(new EntityLayer(data.l_Entities));

        // 4. Automatically build A* navigation grid from level data
        var navGrid:NavGrid = NavGridBuilder.autoBuild(data);

        // 5. Load GPU shader lighting system with LDtk light entities
        var lighting = new LightingSystem(0xFF141424, 0.2);
        lighting.loadFromLevel(data);
        add(lighting);
    }
}
```

---

## ⚡ Performance & Hardware-Richtwerte

`mklib` ist für extrem hohe Performance und minimale Hardware-Anforderungen optimiert. Auf Standard-Office-Notebooks mit integrierter Grafikkarte (Intel HD / UHD / Iris Xe) gelten folgende Richtwerte für stabile 60 FPS:

- 👾 **Sichtbare Sprites:** ~ **2.000 Sprites** (Batch-Rendering via Flixel/OpenFL)
- ⚙️ **Nape Physik-Körper:** ~ **300 aktive Rigid Bodies**
- 💡 **Shader-Lichtquellen:** **32 Lichter zeitgleich auf dem Bildschirm** (unbegrenzt im Level dank Frustum Culling)

---

## 📄 License

MIT License. See [haxelib.json](haxelib.json).