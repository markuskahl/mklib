# mklib — Documentation & API Reference

**`mklib`** is a high-performance Haxe library for seamlessly integrating **HaxeFlixel**, the **LDtk** level editor, and the **Nape** 2D physics engine. It provides comprehensive tooling for automatic level and entity instantiation, a clean physics and collision sensor system, GPU-accelerated lighting, dynamic water reflection shaders, and fast 2D A* pathfinding.

---

## 📚 Table of Contents

1. [**Getting Started & Setup**](getting_started.md)
   - Requirements, Installation & haxelib configuration
   - Project configuration (`Project.xml` & `Data.hx`)
   - Complete minimal example

2. [**State Management (`mklib.state.State`)**](state.md)
   - Generic base state `State<TLevel>`
   - Typed level access (`data`)
   - Nape physics initialization & collision tag registration
   - Automatic memory cleanup & leak prevention (`destroy`)

3. [**Layer System (`TileLayer` & `EntityLayer`)**](layers.md)
   - `TileLayer`: Rendering LDtk tile layers
   - `EntityLayer`: Dynamic entity instantiation via reflection
   - Layer data sources & utilities

4. [**Entities & Game Objects (`EntitySprite` & `EntityNapeSprite`)**](entities.md)
   - Visual entities with custom fields & animations (`EntitySprite`)
   - Physics entities with Nape Body, Shapes & collision tags (`EntityNapeSprite`)
   - Auto-updating shape positions & sensor handling

5. [**Animation System & Macros (`AnimationBuilder` & `AnimationTypes`)**](animation.md)
   - Build-time compile-safe animation generation (`AnimationBuilder.buildDatabase`)
   - JSON animation configuration & spritesheets
   - `AnimationClip`, `FrameConfig`, and `SpriteSheetData` types

6. [**Physics & Collision Sensors (`Listener` & `Tags`)**](physics.md)
   - String-based collision types via LDtk enum `"Tags"`
   - Collision & sensor callbacks (`Listener.addCollisionBeginListener`, `Listener.addSensorBeginListener`, etc.)

7. [**Pathfinding & Navigation (`NavGrid`, `NavGridBuilder`, `AStar`)**](pathfinding.md)
   - 2D grid map with multi-tile sizing and diagonals (`NavGrid`)
   - Auto-building navigation grids from LDtk IntGrid and tile layers (`NavGridBuilder`)
   - Optimized A* algorithm with Euclidean/Manhattan heuristics (`AStar`)

8. [**GPU Lighting System (`LightingSystem`, `Light`, etc.)**](lighting.md)
   - GPU-accelerated 2D lighting with multi-pass shaders
   - Light types: Point, Spot, Torch (flicker), Glow (pulse), Directional
   - Raymarched soft shadows and occluders

9. [**Water Reflection & Wave Shaders (`WaterReflectionShader`, `WaterReflectionPlane`, `EntityWaterReflection`)**](water_reflection.md)
   - Dynamic real-time water wave & reflection shader
   - Full water planes and per-entity reflection sprites
   - Configurable wave amplitude, frequency, foam, and reflection fade

10. [**Tools & Math Utilities (`AspectRatio` & `MathTool`)**](tools_math.md)
    - Aspect ratio calculations & validation (`AspectRatio`)
    - High-precision float rounding & arithmetic fixes (`MathTool`)

---

## 🚀 Quick Start Example

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

        // 1. Initialize Nape physics
        napeInit(0, 300);

        // 2. Render tilemap layer
        add(new TileLayer(data.l_Tiles.identifier));

        // 3. Spawn entities from the "entities" package
        add(new EntityLayer(data.l_Entities));

        // 4. Auto-generate A* pathfinding grid
        var navGrid:NavGrid = NavGridBuilder.autoBuild(data);

        // 5. Add dynamic GPU lighting
        var lighting = new LightingSystem(0xFF141424, 0.2);
        lighting.loadFromLevel(data);
        add(lighting);
    }
}
```

---

## 📄 License

MIT License. See [haxelib.json](../haxelib.json).\n