# State-Management (`mklib.state.State`)

Die Klasse `mklib.state.State<TLevel>` ist das Herzstück deiner Spielzustände in `mklib`. Sie erweitert `flixel.FlxState` und verbindet dein LDtk-Projekt mit dem HaxeFlixel-Lebenszyklus und der Nape-Physik-Engine.

---

## 📋 Übersicht & Definition

```haxe
package mklib.state;

class State<TLevel = Dynamic> extends FlxState {
    public var project:ldtk.Project;
    public var tags:Map<String, nape.callbacks.CbType>;
    public var levelName:String;
    public var data:TLevel;

    public function new(LevelName:String = "Level_0", ?projectInstance:ldtk.Project);
    public function napeInit(gx:Int, gy:Int):Void;
    public function addCbTypes():Void;
}
```

---

## ⚙️ Funktionsweise

### 1. Typisierter Level-Zugriff (`data`)
Beim Instanziieren des States wird das LDtk-Projekt aufgelöst. Wenn kein eigenes `projectInstance` übergeben wird, sucht `State` per Reflection nach der Standardklasse `Data`.

Das angegebene Level (`levelName`, z. B. `"Level_0"` oder `"World_Level_1"`) wird geladen und steht in der Eigenschaft `data` typisiert zur Verfügung:

```haxe
class PlayState extends State<Data.Data_Level> {
    override public function create() {
        super.create();

        // Direkter Zugriff auf LDtk-Layer und Entities:
        trace("Levelbreite (Pixel): " + data.pxWid);
        trace("Kachelebene: " + data.l_Tiles.identifier);
    }
}
```

### 2. Nape-Physik initialisieren (`napeInit`)
Die Methode `napeInit(gx, gy)` führt alle notwendigen Schritte zur Vorbereitung des Nape-Physikraums aus:
- Startet `FlxNapeSpace.init()`
- Setzt die globale Schwerkraft (z. B. `gx = 0, gy = 300`)
- Ruft intern `addCbTypes()` auf, um Kollisionstags zu registrieren

```haxe
// Initialisiert die Physik mit Schwerkraft nach unten
napeInit(0, 300);
```

### 3. Automatische CbTypes aus LDtk-Enums (`addCbTypes`)
In LDtk kannst du ein Enum mit dem Namen `"Tags"` anlegen (z. B. mit Werten `Player`, `Solid`, `Enemy`, `Coin`, `Hazard`).
`State.addCbTypes()` liest dieses Enum automatisch aus und erstellt für jeden Enum-Wert eine entsprechende `nape.callbacks.CbType`-Instanz in der `tags`-Map.

Diese CbTypes können später bequem über `mklib.tools.Tags.get("Player")` oder `mklib.physic.Listener` referenziert werden.

---

## 💡 Code-Beispiel: Level-Wechsel

```haxe
package;

import flixel.FlxG;
import mklib.state.State;
import mklib.layer.TileLayer;
import mklib.layer.EntityLayer;

class LevelState extends State<Data.Data_Level> {
    public function new(nextLevel:String = "Level_0") {
        super(nextLevel);
    }

    override public function create():Void {
        super.create();
        napeInit(0, 300);

        add(new TileLayer(data.l_Tiles.identifier));
        add(new EntityLayer(data.l_Entities));
    }

    public function goToNextLevel():Void {
        // Wechselt zu Level_1
        FlxG.switchState(new LevelState("Level_1"));
    }
}
```
