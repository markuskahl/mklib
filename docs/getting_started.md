# Schnellstart & Einrichtung (Getting Started)

In dieser Anleitung erfährst du, wie du **`mklib`** in dein HaxeFlixel-Projekt einbindest, LDtk konfigurierst und das erste spielbare Level aufsetzt.

---

## 1. Voraussetzungen & Abhängigkeiten

`mklib` basiert auf Haxe 4+ und setzt folgende Haxelib-Pakete voraus:

- **`flixel`** (z. B. `5.8.0`)
- **`flixel-addons`** (z. B. `3.2.3`)
- **`nape-haxe4`** (z. B. `2.0.22`)
- **`openfl`** (z. B. `9.3.2`)
- **`ldtk-haxe-api`** (z. B. `1.5.3-rc.1`)

In deiner `Project.xml`:

```xml
<haxelib name="openfl" />
<haxelib name="flixel" />
<haxelib name="flixel-addons" />
<haxelib name="nape-haxe4" />
<haxelib name="ldtk-haxe-api" />
<haxelib name="mklib" />
```

---

## 2. LDtk Projekt-Setup (`Data.hx`)

`ldtk-haxe-api` nutzt ein Build-Makro, um deine `.ldtk`-Projektdatei zur Compile-Zeit zu parsen und typsichere Klassen zu generieren.

Erstelle eine Datei `source/Data.hx`:

```haxe
package;

private typedef _Tmp = haxe.macro.MacroType<[ ldtk.Project.build("assets/data/map.ldtk") ]>;
```

Dadurch erzeugt der Haxe-Compiler unter anderem:
- Die globale Klasse `Data` (erbt von `ldtk.Project`)
- Den Typ `Data.Data_Level` (typisierte Leveldaten mit Feldern für alle Layer)
- Typisierte Entity-Klassen wie `Data.Entity_Hero`, `Data.Entity_Platform` usw.

---

## 3. Haupt-Einstiegspunkt (`Main.hx`)

In deiner `Main.hx` startest du wie gewohnt dein Flixel-Spiel:

```haxe
package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {
    public function new() {
        super();
        addChild(new FlxGame(320, 180, PlayState, 60, 60, true, false));
    }
}
```

---

## 4. Erstellen des `PlayState`

Erbe von `mklib.state.State<Data.Data_Level>`:

```haxe
package;

import flixel.FlxG;
import mklib.state.State;
import mklib.layer.TileLayer;
import mklib.layer.EntityLayer;
import mklib.path.NavGridBuilder;
import mklib.path.NavGrid;

class PlayState extends State<Data.Data_Level> {
    public var tileLayer:TileLayer;
    public var entityLayer:EntityLayer;
    public var navGrid:NavGrid;

    public function new() {
        // Lädt standardmäßig "Level_0"
        super("Level_0");
    }

    override public function create():Void {
        super.create();

        // Nape-Physikraum initialisieren (X-Gravitation: 0, Y-Gravitation: 300)
        napeInit(0, 300);

        // Tile-Layer rendern (Name entspricht dem Layer-Identifier in LDtk)
        tileLayer = new TileLayer(data.l_Tiles.identifier);
        add(tileLayer);

        // Entity-Layer laden (instanziiert Klassen im Package "entities")
        entityLayer = new EntityLayer(data.l_Entities);
        add(entityLayer);

        // A*-Navigationsraster automatisch generieren
        navGrid = NavGridBuilder.autoBuild(data);
    }
}
```

---

## 5. Entities definieren

Erstelle deine Entity-Klassen im Package `entities` (z. B. `source/entities/Hero.hx`):

```haxe
package entities;

import flixel.util.FlxColor;
import mklib.entity.EntitySprite;
import ldtk.Entity;

@:keep
class Hero extends EntitySprite {
    public function new(entity:ldtk.Entity) {
        super(entity);
        makeGraphic(entity.width, entity.height, FlxColor.WHITE);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        // Spiellogik...
    }
}
```

> [!TIP]
> Verwende die Annotation `@:keep` an Entity-Klassen, damit der Haxe-DCE (Dead Code Elimination) Compiler die Klassen nicht entfernt, da sie per Reflection (`Type.resolveClass`) instanziiert werden.
